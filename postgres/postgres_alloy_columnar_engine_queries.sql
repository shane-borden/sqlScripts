-- Copyright 2025 shaneborden
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     https://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

/* Helpful Links 
https://cloud.google.com/alloydb/docs/columnar-engine/manage-content-recommendations
https://medium.com/google-cloud/alloydbs-columnar-store-how-to-preserve-it-during-failovers-and-restarts-141a8466772 */

/* determine columnar engine settings */
select name,setting,boot_val,reset_val from pg_settings where name like '%google_columnar_engine%' order by 1;

/* Set a population policy */
SELECT google_columnar_engine_add_policy('RECOMMEND_AND_POPULATE_COLUMNS','IMMEDIATE',0,'HOURS');
--IMMEDIATE - runs immediately one time. When you use this value, specify 0 and 'HOURS' for the duration and time_unit parameters.
--AFTER - runs once when the duration time_unit amount of time passes
--EVERY - runs repeatedly every duration time_unit amount of time

/* Execute a recommendation */
SELECT google_columnar_engine_run_recommendation(102400,'PERFORMANCE_OPTIMAL');

/* check from psql if columnar is enabled */
postgres=# show google_columnar_engine.enabled;
 google_columnar_engine.enabled
--------------------------------
 off
 
 /* To show columnar messages in cloud logging */
textPayload=~"population_jobs.cc|Invalidating columnar|population.cc|columnar"
 
/* To Force a SEQ Scan for invalid blocks; this is the default now; Use this for debugging only */
set session google_columnar_engine.rowstore_scan_mode to 1;

/* To show the refresh threshold (based on invalid blocks vs total blocks) */
show google_columnar_engine.refresh_threshold_percentage;

/* To show the number of DML operations on base table required before the refresh_threshold_percentage kicks in */
show google_columnar_engine.refresh_threshold_scan_count;

/* to force a columnar scan; generally isnt needed, this is for testing / debugging only */
set session google_columnar_engine.force_columnar_mode to true;

/* other GUC to influence CE costing, this is for testing / debugging only */
set session enable_cache_aware_costing = true 
set session google_columnar_engine.bump_columnar_scan_cost = false

/* to force columnar using pg_hint_plan */
/*+ ColumnarScan(xxx) */

/* To manually run the job: */
SELECT google_columnar_engine_recommend();

/* To view the list of recommended columns: */
SELECT * FROM g_columnar_recommended_columns;
SELECT database_name, schema_name, relation_name, column_name FROM g_columnar_recommended_columns;

/* To add a table */
SELECT google_columnar_engine_add('t1');
select google_columnar_engine_add(relation => 'public.t1', in_background => TRUE);

/* To add a table with a subset of columns */
SELECT google_columnar_engine_add('public.t1', 'a,b,c,f,');

/* To remove a table */
SELECT google_columnar_engine_drop('t1');
SELECT google_columnar_engine_drop('public.t1');
 
/* To disable columnar for a query in a session */
set session google_columnar_engine.enable_columnar_scan TO 'off';

/* to Refresh a table */
select google_columnar_engine_refresh('public.t1');

select google_columnar_engine_refresh(relation => 'public.t1', in_background => TRUE);

/* to check columar jobs */
select * from g_columnar_jobs;

/* To view the list of recommended column detail: */
SELECT
	crc.database_name as database_name,
	crc.schema_name AS schema_name,
	crc.relation_name AS table_name,
	pi.inhparent::regclass,
	crc.column_name,
	crc.column_format,
	crc.compression_level,
	crc.estimated_size_in_bytes
FROM public.g_columnar_recommended_columns_internal /* g_columnar_recommended_columns */ crc
JOIN pg_stat_all_tables ps
	ON ps.schemaname::text = crc.schema_name 
		AND ps.relname::text = crc.relation_name
JOIN pg_class pc
	ON ps.relid = pc.oid
LEFT JOIN pg_catalog.pg_inherits pi
	ON ps.relid = pi.inhrelid
ORDER BY 1,2,4 NULLS LAST;

/* to display table name without column detail */
SELECT
	crc.database_name as database_name,
	crc.schema_name AS schema_name,
	crc.relation_name AS table_name,
	pi.inhparent::regclass,
	crc.column_format,
	crc.compression_level,
	SUM(crc.estimated_size_in_bytes) as total_bytes,
	pg_size_pretty(SUM(crc.estimated_size_in_bytes)) as pretty_total_size
FROM g_columnar_recommended_columns crc
JOIN pg_stat_all_tables ps
	ON ps.schemaname::text = crc.schema_name 
		AND ps.relname::text = crc.relation_name
JOIN pg_class pc
	ON ps.relid = pc.oid
LEFT JOIN pg_catalog.pg_inherits pi
	ON ps.relid = pi.inhrelid
GROUP BY crc.database_name, crc.schema_name, crc.relation_name, pi.inhparent::regclass,crc.column_format,crc.compression_level
ORDER BY 1,2,4 NULLS LAST;


/* List of items in the column store */
SELECT
    database_name,
    schema_name,
    relation_name,
    column_name,
    column_type,
    status,
    size_in_bytes,
    last_accessed_time,
    num_times_accessed
FROM
    g_columnar_columns;

SELECT
    *
FROM
    g_columnar_columns;

SELECT
    *
FROM
    g_columnar_relations
ORDER BY
    relation_name;


/* To see current status of items in columnstore */
SELECT
    schema_name,
    relation_name,
    status,
    swap_status,
    sum(end_block - start_block) ttl_block,
    sum(invalid_block_count) invalid_block,
    CASE WHEN sum(end_block - start_block) > 0 THEN
       round(100 * sum(invalid_block_count) / sum(end_block - start_block), 1)
    ELSE 0.0
    END AS invalid_block_perc,
    pg_size_pretty(sum(size)) ttl_size,
    pg_size_pretty(sum(cached_size_bytes)) ttl_cached_size
FROM
    g_columnar_units
WHERE
    g_columnar_units.database_name = current_database()
    and g_columnar_units.relation_name like '%'
GROUP BY
    schema_name,
    relation_name,
    status,
    swap_status
ORDER BY
    relation_name;

/* Check utilization of columnar memory */
SELECT
    memory_name,
    memory_total / 1024 / 1024 memory_total_MB,
    memory_available / 1024 / 1024 memory_available_MB,
    memory_available_percentage,
    pg_size_pretty(google_columnar_engine_storage_cache_used()*1024*1024) AS cc_storage_cache_used_mb,
    pg_size_pretty(google_columnar_engine_storage_cache_available()*1024*1024) AS cc_storage_cache_avail_mb,
    pg_size_pretty((google_columnar_engine_storage_cache_available() - google_columnar_engine_storage_cache_used())*1024*1024) as cc_storage_cache_free_mb
FROM
    g_columnar_memory_usage;

/* Check non default "google" postgres params */
SELECT
    s.name AS "Parameter",
    pg_catalog.current_setting(s.name) AS "Value"
FROM
    pg_catalog.pg_settings s
WHERE
    1=1
    --AND s.source <> 'default'
    --AND s.setting IS DISTINCT FROM s.boot_val
    AND lower(s.name) LIKE '%google%'
ORDER BY
    1;

/* To see Columnar engine column Swap-out */
SELECT
	memory_name,
    pg_size_pretty(memory_total) AS cc_allocated,
    pg_size_pretty(memory_total - memory_available) AS cc_consumed,
    pg_size_pretty(memory_available) cc_available,
    --google_columnar_engine_storage_cache_total() as cc_storage_cache_avail_mb, /* Future function */
    google_columnar_engine_storage_cache_used() AS cc_storage_cache_used_mb,
    google_columnar_engine_storage_cache_available() AS cc_storage_cache_avail_mb,
    CASE WHEN google_columnar_engine_storage_cache_used() > 0 THEN
        'Swapped-out Column(s)'
    ELSE
        NULL
    END AS "SwapOut",
    (
        SELECT
            CONCAT_WS('-', STRING_AGG(DISTINCT g_columnar_units.relation_name, '/'), STATUS, swap_status)
        FROM
            g_columnar_units
        GROUP BY
            status,
            swap_status) AS current_obj
FROM
    g_columnar_memory_usage
WHERE
    memory_name = 'main_pool';


/* To populate many tables manually */
do
$$
declare
    f record;
    gResult numeric;
    begin_timestamp timestamp;
    age_text text;
begin
    for f in SELECT 
             n.nspname as schemaname,
             c.oid::regclass::text AS table_name,
             c.oid as oid,
             pi.inhparent::regclass::text AS top_table_name,
             pg_total_relation_size(c.oid) as size,
             pg_size_pretty(pg_total_relation_size(c.oid)) as pretty_size
             FROM pg_class c
             JOIN pg_namespace n on c.relnamespace = n.oid
             LEFT JOIN pg_inherits pi on c.oid = pi.inhrelid
             WHERE c.relkind IN ('r', 't', 'm')
             AND (n.nspname NOT IN('pg_toast') AND n.nspname LIKE '%')
             --AND (c.oid::regclass::text LIKE '%' AND pi.inhparent::regclass::text LIKE '%')
             AND (c.oid::regclass::text LIKE 'table_name%' AND pi.inhparent::regclass::text LIKE 'table_partiton_name%')
             ORDER BY 2 NULLS LAST
    loop
    	BEGIN
    		SELECT clock_timestamp() into begin_timestamp;
			--SELECT google_columnar_engine_add(f.oid,'[comma separated column list]') into gResult; /* us this if there are specific cols */
			SELECT google_columnar_engine_add(f.oid) into gResult;
			SELECT age(clock_timestamp(),begin_timestamp)::text into age_text;
			raise notice ' % % % % % %', f.top_table_name, f.table_name, 'google_columnar_engine_add result: ', gResult, ' time: ', age_text;
		EXCEPTION WHEN OTHERS THEN
			raise notice ' % % % %', f.top_table_name, f.table_name, 'exception result', gResult;
		END;
    end loop;
end;
$$;


/* To refresh many tables manually */
do
$$
declare
    f record;
    gResult numeric;
begin
    for f in SELECT 
             n.nspname as schemaname,
             c.oid::regclass::text AS table_name,
             c.oid as oid,
             pi.inhparent::regclass::text AS top_table_name,
             pg_total_relation_size(c.oid) as size,
             pg_size_pretty(pg_total_relation_size(c.oid)) as pretty_size
             FROM pg_class c
             JOIN pg_namespace n on c.relnamespace = n.oid
             LEFT JOIN pg_inherits pi on c.oid = pi.inhrelid
             WHERE c.relkind IN ('r', 't', 'm')
             AND (n.nspname NOT IN('pg_toast') AND n.nspname LIKE '%')
             --AND (c.oid::regclass::text LIKE '%' AND pi.inhparent::regclass::text LIKE '%')
             AND (c.oid::regclass::text LIKE 'table_name%' AND pi.inhparent::regclass::text LIKE 'table_partiton_name%')
             ORDER BY 2 NULLS LAST
    loop
    	BEGIN
			SELECT google_columnar_engine_refresh(f.oid) into gResult;
			raise notice ' % % % %', f.top_table_name, f.table_name, 'google_columnar_engine_refresh result: ', gResult;
		EXCEPTION WHEN OTHERS THEN
			raise notice ' % % % %', f.top_table_name, f.table_name, 'exception result', gResult;
		END;
    end loop;
end;
$$;

/* To drop many tables manually */
do
$$
declare
    f record;
    gResult numeric;
begin
    for f in SELECT 
             n.nspname as schemaname,
             c.oid::regclass::text AS table_name,
             c.oid as oid,
             pi.inhparent::regclass::text AS top_table_name,
             pg_total_relation_size(c.oid) as size,
             pg_size_pretty(pg_total_relation_size(c.oid)) as pretty_size
             FROM pg_class c
             JOIN pg_namespace n on c.relnamespace = n.oid
             LEFT JOIN pg_inherits pi on c.oid = pi.inhrelid
             JOIN g_columnar_units ce on (ce.schema_name = n.nspname and ce.relation_name = c.oid::regclass::text)
             WHERE c.relkind IN ('r', 't', 'm')
             AND (n.nspname NOT IN('pg_toast') AND n.nspname LIKE '%')
             --AND (c.oid::regclass::text LIKE '%' AND pi.inhparent::regclass::text LIKE '%')
             AND (c.oid::regclass::text LIKE 'table_name%' AND pi.inhparent::regclass::text LIKE 'table_partiton_name%')
             ORDER BY 2 NULLS LAST
    loop
    	BEGIN
			SELECT google_columnar_engine_drop(f.oid) into gResult;
			raise notice ' % % % %', f.top_table_name, f.table_name, 'google_columnar_engine_add result: ', gResult;
		EXCEPTION WHEN OTHERS THEN
			raise notice ' % % % %', f.top_table_name, f.table_name, 'exception result', gResult;
		END;
    end loop;
end;
$$;