/*
	https://wiki.postgresql.org/wiki/Index_Maintenance
	https://bucardo.org/check_postgres/
*/

/* indexdes supporting pk constraints */
\prompt 'Enter schema_name: ' vSchemaName
SELECT
    n.nspname schema_name,
    c.conname constraint_name,
    c.contype constraint_type,
    i.relname index_name,
    t.relname table_name
FROM
    pg_constraint c
    JOIN pg_namespace n ON (c.connamespace = n.oid
            AND n.nspname = :'vSchemaName')
    JOIN pg_class i ON (c.conindid = i.oid)
    JOIN pg_class t ON (c.conrelid = t.oid)
WHERE
    c.contype = 'p';

/* Index Information Query */
\prompt 'Enter schema_name: ' vSchemaName
SELECT
    pg_class.relname,
    pg_size_pretty(pg_class.reltuples::bigint)            AS rows_in_bytes,
    pg_class.reltuples                                    AS num_rows,
    COUNT(*)                                              AS total_indexes,
    COUNT(*) FILTER ( WHERE indisunique)                  AS unique_indexes,
    COUNT(*) FILTER ( WHERE indnatts = 1 )                AS single_column_indexes,
    COUNT(*) FILTER ( WHERE indnatts IS DISTINCT FROM 1 ) AS multi_column_indexes
FROM
    pg_namespace
    LEFT JOIN pg_class ON pg_namespace.oid = pg_class.relnamespace
    LEFT JOIN pg_index ON pg_class.oid = pg_index.indrelid
WHERE
    pg_namespace.nspname = :'vSchemaName' AND
    pg_class.relkind = 'r'
GROUP BY pg_class.relname, pg_class.reltuples
ORDER BY pg.namespace.nspname, pg_class.reltuples DESC;

/* Index Usage Information */
\prompt 'Enter schema_name: ' vSchemaName
SELECT
    t.schemaname,
    t.tablename,
    c.reltuples::bigint                            AS num_rows,
    pg_size_pretty(pg_relation_size(c.oid))        AS table_size,
    psai.indexrelname                              AS index_name,
    pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
    CASE WHEN i.indisunique THEN 'Y' ELSE 'N' END  AS "unique",
    psai.idx_scan                                  AS number_of_scans,
    psai.idx_tup_read                              AS tuples_read,
    psai.idx_tup_fetch                             AS tuples_fetched
FROM
    pg_tables t
    LEFT JOIN pg_class c ON t.tablename = c.relname
    LEFT JOIN pg_index i ON c.oid = i.indrelid
    LEFT JOIN pg_stat_all_indexes psai ON i.indexrelid = psai.indexrelid
WHERE
    t.schemaname NOT IN ('pg_catalog', 'information_schema','partman')
    AND t.schemaname LIKE ('%')
ORDER BY 1, 2;


/* Duplicate Indexes w/o relname */
SELECT pg_size_pretty(sum(pg_relation_size(idx))::bigint) as size,
       (array_agg(idx))[1] as idx1, (array_agg(idx))[2] as idx2,
       (array_agg(idx))[3] as idx3, (array_agg(idx))[4] as idx4
FROM (
    SELECT indexrelid::regclass as idx, (indrelid::text ||E'\n'|| indclass::text ||E'\n'|| indkey::text ||E'\n'||
                                         coalesce(indexprs::text,'')||E'\n' || coalesce(indpred::text,'')) as key
    FROM pg_index) sub
GROUP BY key HAVING count(*)>1
ORDER BY sum(pg_relation_size(idx)) DESC;

/* Duplicate Indexes w/ relname */
SELECT
	n.nspname AS schema,
    c.relname AS relname,
    sum(pg_relation_size(idx))::bigint AS size,
    pg_size_pretty(sum(pg_relation_size(idx))::bigint) AS pretty_size,
    (array_agg(idx))[1] AS idx1,
    (array_agg(idx))[2] AS idx2,
    (array_agg(idx))[3] AS idx3,
    (array_agg(idx))[4] AS idx4,
    (array_agg(idx))[5] AS idx5,
    (array_agg(idx))[6] AS idx6,
    (array_agg(idx))[7] AS idx7,
    (array_agg(idx))[8] AS idx8,
    (array_agg(idx))[9] AS idx9,
    (array_agg(idx))[10] AS idx10
FROM (
	SELECT 
		i.indrelid,
		i.indexrelid::regclass AS idx,
		(i.indrelid::text || E'\n' || indclass::text || E'\n' || indkey::text || E'\n' || coalesce(indexprs::text, '') || E'\n' || SUBSTRING(pi.indexdef FROM (POSITION('ON' IN pi.indexdef)))) as key
		--(indrelid::text || E'\n' || indclass::text || E'\n' || indkey::text || E'\n' || coalesce(indexprs::text, '') || E'\n' || coalesce(indpred::text, '')) AS key
	FROM
		pg_index i
		JOIN pg_class c ON (i.indexrelid = c.oid)
		JOIN pg_indexes pi ON (pi.indexname = c.relname)) sub
    JOIN pg_class c ON (c.oid = sub.indrelid)
    JOIN pg_namespace n ON (c.relnamespace = n.oid)
GROUP BY
	n.nspname,
    relname,
    key
HAVING
    count(*) > 1
ORDER BY
    sum(pg_relation_size(idx)) DESC;
    

/* 
	https://github.com/dataegret/pg-utils/blob/master/sql/low_used_indexes.sql
*/

SELECT pg_stat_user_indexes.schemaname || '.' || pg_stat_user_indexes.relname tablemane
     , pg_stat_user_indexes.indexrelname
     , pg_stat_user_indexes.idx_scan
     , psut.write_activity
     , psut.seq_scan
     , psut.n_live_tup
     , pg_size_pretty (pg_relation_size (pg_index.indexrelid::regclass)) as size
  from pg_stat_user_indexes
  join pg_index
    ON pg_stat_user_indexes.indexrelid = pg_index.indexrelid
  join (select pg_stat_user_tables.relid
             , pg_stat_user_tables.seq_scan
             , pg_stat_user_tables.n_live_tup
             , ( coalesce (pg_stat_user_tables.n_tup_ins, 0)
               + coalesce (pg_stat_user_tables.n_tup_upd, 0)
               - coalesce (pg_stat_user_tables.n_tup_hot_upd, 0)
               + coalesce (pg_stat_user_tables.n_tup_del, 0)
               ) as write_activity
          from pg_stat_user_tables) psut
    on pg_stat_user_indexes.relid = psut.relid
 where pg_index.indisunique is false
   and pg_stat_user_indexes.idx_scan::float / (psut.write_activity + 1)::float < 0.01
   and psut.write_activity > case when pg_is_in_recovery () then -1 else 10000 end
  order by 4 desc, 1, 2;
  
with indexes as (
    select * from pg_stat_user_indexes
)
select table_name,
pg_size_pretty(table_size) as table_size,
index_name,
pg_size_pretty(index_size) as index_size,
idx_scan as index_scans,
round((free_space*100/index_size)::numeric, 1) as waste_percent,
pg_size_pretty(free_space) as waste
from (
    select (case when schemaname = 'public' then format('%I', p.relname) else format('%I.%I', schemaname, p.relname) end) as table_name,
    indexrelname as index_name,
    (select (case when avg_leaf_density = 'NaN' then 0
        else greatest(ceil(index_size * (1 - avg_leaf_density / (coalesce((SELECT (regexp_matches(reloptions::text, E'.*fillfactor=(\\d+).*'))[1]),'90')::real)))::bigint, 0) end)
        from pgstatindex(p.indexrelid::regclass::text)
    ) as free_space,
    pg_relation_size(p.indexrelid) as index_size,
    pg_relation_size(p.relid) as table_size,
    idx_scan
    from indexes p
    join pg_class c on p.indexrelid = c.oid
    join pg_index i on i.indexrelid = p.indexrelid
    where pg_get_indexdef(p.indexrelid) like '%USING btree%' and
    i.indisvalid and (c.relpersistence = 'p' or not pg_is_in_recovery())
    --put your index name/mask here
    -- and indexrelname = 'transactions_p01_user_id_idx'
) t
order by free_space desc
limit 100;


/* Find Unused Indexes */
WITH table_scans as (
    SELECT relid,
        tables.idx_scan + tables.seq_scan as all_scans,
        ( tables.n_tup_ins + tables.n_tup_upd + tables.n_tup_del ) as writes,
                pg_relation_size(relid) as table_size
        FROM pg_stat_all_tables as tables
        WHERE schemaname not in ('pg_toast','pg_catalog','partman')
),
all_writes as (
    SELECT sum(writes) as total_writes
    FROM table_scans
),
indexes as (
    SELECT idx_stat.relid, idx_stat.indexrelid,
        idx_stat.schemaname, idx_stat.relname as tablename,
        idx_stat.indexrelname as indexname,
        idx_stat.idx_scan,
        pg_relation_size(idx_stat.indexrelid) as index_bytes,
        indexdef ~* 'USING btree' AS idx_is_btree
    FROM pg_stat_user_indexes as idx_stat
        JOIN pg_index
            USING (indexrelid)
        JOIN pg_indexes as indexes
            ON idx_stat.schemaname = indexes.schemaname
                AND idx_stat.relname = indexes.tablename
                AND idx_stat.indexrelname = indexes.indexname
    WHERE pg_index.indisunique = FALSE
),
index_ratios AS (
SELECT schemaname, tablename, indexname,
    idx_scan, all_scans,
    round(( CASE WHEN all_scans = 0 THEN 0.0::NUMERIC
        ELSE idx_scan::NUMERIC/all_scans * 100 END),2) as index_scan_pct,
    writes,
    round((CASE WHEN writes = 0 THEN idx_scan::NUMERIC ELSE idx_scan::NUMERIC/writes END),2)
        as scans_per_write,
    pg_size_pretty(index_bytes) as index_size_pretty,
    pg_size_pretty(table_size) as table_size,
    idx_is_btree, 
    index_bytes as index_size_bytes
    FROM indexes
    JOIN table_scans
    USING (relid)
),
index_groups AS (
SELECT 'Never Used Indexes' as reason, *, 1 as grp
FROM index_ratios
WHERE
    idx_scan = 0
    and idx_is_btree
UNION ALL
SELECT 'Low Scans, High Writes' as reason, *, 2 as grp
FROM index_ratios
WHERE
    scans_per_write <= 1
    and index_scan_pct < 10
    and idx_scan > 0
    and writes > 100
    and idx_is_btree
UNION ALL
SELECT 'Seldom Used Large Indexes' as reason, *, 3 as grp
FROM index_ratios
WHERE
    index_scan_pct < 5
    and scans_per_write > 1
    and idx_scan > 0
    and idx_is_btree
    and index_size_bytes > 100000000
UNION ALL
SELECT 'High-Write Large Non-Btree' as reason, index_ratios.*, 4 as grp 
FROM index_ratios, all_writes
WHERE
    ( writes::NUMERIC / ( total_writes + 1 ) ) > 0.02
    AND NOT idx_is_btree
    AND index_size_bytes > 100000000
ORDER BY grp, index_size_bytes DESC )
SELECT reason, schemaname, tablename, indexname,
    index_scan_pct, scans_per_write, index_size_pretty,index_size_bytes, table_size
FROM index_groups
WHERE tablename like '%'
ORDER BY reason, index_size_bytes,table_size;


/* Index Cache Hit Ratio */
SELECT
relname,
indexrelname,
sum(idx_blks_read) as idx_read,
sum(idx_blks_hit)  as idx_hit,
ROUND((sum(idx_blks_hit) - sum(idx_blks_read)) / sum(idx_blks_hit),4) as ratio
FROM pg_statio_user_indexes
WHERE (idx_blks_read > 0 and idx_blks_hit > 0) 
--AND relname like '%transaction%' AND indexrelname like '%user%'
GROUP BY
relname,
indexrelname;
