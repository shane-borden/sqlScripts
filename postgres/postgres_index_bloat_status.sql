-- Copyright 2024 shaneborden
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

WITH btree_index_atts AS (
    SELECT nspname, 
        indexclass.relname as index_name, 
        indexclass.reltuples, 
        indexclass.relpages, 
        indrelid,
        indexclass.relam,
        tableclass.relname as tablename,
        indexrelid as index_oid,
        pg_attribute.attname,
        pg_attribute.attnum
    FROM pg_index
    JOIN pg_class AS indexclass ON pg_index.indexrelid = indexclass.oid
    JOIN pg_class AS tableclass ON pg_index.indrelid = tableclass.oid
    JOIN pg_namespace ON pg_namespace.oid = indexclass.relnamespace
    JOIN pg_am ON indexclass.relam = pg_am.oid
    JOIN pg_attribute ON pg_attribute.attrelid = tableclass.oid 
    	AND pg_attribute.attnum = ANY(indkey)
    WHERE pg_am.amname = 'btree' and indexclass.relpages > 0
		AND nspname NOT IN ('pg_catalog','information_schema')
		AND tableclass.relname like '%'
    ),
index_item_sizes AS (
    SELECT
    ind_atts.nspname, ind_atts.index_name, 
    ind_atts.reltuples, ind_atts.relpages, ind_atts.relam,
    indrelid AS table_oid, index_oid,
    current_setting('block_size')::numeric AS bs,
    8 AS maxalign,
    24 AS pagehdr,
    CASE WHEN max(coalesce(pg_stats.null_frac,0)) = 0
        THEN 2
        ELSE 6
    END AS index_tuple_hdr,
    sum( (1-coalesce(pg_stats.null_frac, 0)) * coalesce(pg_stats.avg_width, 1024) ) AS nulldatawidth
    FROM btree_index_atts AS ind_atts 
    left JOIN pg_stats ON pg_stats.schemaname = ind_atts.nspname
          -- stats for regular index columns
          AND ( (pg_stats.tablename = ind_atts.tablename AND pg_stats.attname = ind_atts.attname) 
          -- stats for functional indexes
          OR   (pg_stats.tablename = ind_atts.index_name AND pg_stats.attname = ind_atts.attname))
    WHERE ind_atts.attnum > 0
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),
index_aligned_est AS (
    SELECT maxalign, bs, nspname, index_name, reltuples,
        relpages, relam, table_oid, index_oid,
        coalesce (
            ceil (
                reltuples * ( 6 
                    + maxalign 
                    - CASE
                        WHEN index_tuple_hdr%maxalign = 0 THEN maxalign
                        ELSE index_tuple_hdr%maxalign
                      END
                    + nulldatawidth 
                    + maxalign 
                    - CASE /* Add padding to the data to align on MAXALIGN */
                        WHEN nulldatawidth::integer%maxalign = 0 THEN maxalign
                        ELSE nulldatawidth::integer%maxalign
                      END
                )::numeric 
              / ( bs - pagehdr::NUMERIC )
              +1 )
         , 0 )
      as expected
    FROM index_item_sizes
),
raw_bloat AS (
    SELECT current_database() as dbname, nspname, pg_class.relname AS table_name, index_name,
        bs*(index_aligned_est.relpages)::bigint AS totalbytes, expected,
        CASE
            WHEN index_aligned_est.relpages <= expected 
                THEN 0
                ELSE bs*(index_aligned_est.relpages-expected)::bigint 
            END AS wastedbytes,
        CASE
            WHEN index_aligned_est.relpages <= expected
                THEN 0 
                ELSE bs*(index_aligned_est.relpages-expected)::bigint * 100 / (bs*(index_aligned_est.relpages)::bigint) 
            END AS realbloat,
        pg_relation_size(index_aligned_est.table_oid) as table_bytes,
        stat.idx_scan as index_scans
    FROM index_aligned_est
    JOIN pg_class ON pg_class.oid=index_aligned_est.table_oid
    JOIN pg_stat_user_indexes AS stat ON index_aligned_est.index_oid = stat.indexrelid
),
format_bloat AS (
SELECT dbname as database_name, nspname as schema_name, table_name, index_name,
        round(realbloat) as bloat_pct, round(wastedbytes/(1024^2)::NUMERIC) as bloat_mb,
        round(totalbytes/(1024^2)::NUMERIC,3) as index_mb,
        round(table_bytes/(1024^2)::NUMERIC,3) as table_mb,
        index_scans
FROM raw_bloat
)
-- final query outputting the bloated indexes
-- change the where and order by to change
-- what shows up as bloated
SELECT *
FROM format_bloat
--WHERE ( bloat_pct > 50 and bloat_mb > 10 )
--WHERE index_name like '%_user_id_idx'
ORDER BY bloat_pct DESC NULLS LAST;