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

/* Table Sizes */
SELECT 
n.nspname as schemaname,
c.oid::regclass::text AS table_name, 
pi.inhparent::regclass::text AS top_table_name,
pg_total_relation_size(c.oid) as size,
pg_size_pretty(pg_total_relation_size(c.oid)) as pretty_size
FROM pg_class c
JOIN pg_namespace n on c.relnamespace = n.oid
LEFT JOIN pg_inherits pi on c.oid = pi.inhrelid
WHERE c.relkind IN ('r', 't', 'm')
AND (n.nspname NOT IN('pg_toast') AND n.nspname LIKE '%')
AND (c.oid::regclass::text LIKE '%' and pi.inhparent::regclass::text LIKE '%')
ORDER BY 2 NULLS LAST;

SELECT
  *,
  pg_size_pretty(table_bytes) AS table,
  pg_size_pretty(toast_bytes) AS toast,
  pg_size_pretty(index_bytes) AS index,
  pg_size_pretty(total_bytes) AS total
FROM (
  SELECT
    *, total_bytes - index_bytes - COALESCE(toast_bytes, 0) AS table_bytes
  FROM (
    SELECT
      c.oid,
      n.nspname AS table_schema,
      c.relname AS table_name,
      c.reltuples AS row_estimate,
      pct.relname AS toast_table_name,
      pg_total_relation_size(c.oid) AS total_bytes,
      pg_indexes_size(c.oid) AS index_bytes,
      pg_total_relation_size(c.reltoastrelid) AS toast_bytes
    FROM
      pg_class c
      JOIN pg_class pct ON (c.reltoastrelid = pct.oid)
      LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
  ) a
) a
WHERE table_schema like '%'
AND table_name like '%'
AND total_bytes > 0
ORDER BY table_name DESC;

/* Index Sizes */
SELECT
n.nspname as schemaname,
pgi.tablename as tablename,
c.oid::regclass::text AS index_name, 
pi.inhparent::regclass::text AS top_index_name,
pg_total_relation_size(c.oid) as size,
pg_size_pretty(pg_total_relation_size(c.oid)) as pretty_size
FROM pg_class c
JOIN pg_namespace n on c.relnamespace = n.oid
JOIN pg_indexes pgi on pgi.indexname = c.oid::regclass::text and pgi.schemaname = n.nspname
LEFT JOIN pg_inherits pi on c.oid = pi.inhrelid
WHERE c.relkind IN ('i')
AND (n.nspname NOT IN('pg_toast') AND n.nspname LIKE '%')
AND (c.oid::regclass::text LIKE '%' and pi.inhparent::regclass::text LIKE '%')
ORDER BY 4 NULLS LAST;

/* Temp Table Size */
SELECT
        n.nspname as SchemaName
        ,c.relname as RelationName
        ,CASE c.relkind
        WHEN 'r' THEN 'table'
        WHEN 'v' THEN 'view'
        WHEN 'i' THEN 'index'
        WHEN 'S' THEN 'sequence'
        WHEN 's' THEN 'special'
        END as RelationType
        ,pg_catalog.pg_get_userbyid(c.relowner) as RelationOwner
        ,pg_size_pretty(pg_relation_size(n.nspname ||'.'|| c.relname)) as RelationSize
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n
                ON n.oid = c.relnamespace
WHERE  c.relkind IN ('r','s')
AND  (n.nspname !~ '^pg_toast' and nspname like 'pg_temp%')
ORDER BY pg_relation_size(n.nspname ||'.'|| c.relname) DESC;

/* String Columns + live tuples + table size*/
SELECT
    c.table_catalog,
    c.table_schema,
    c.table_name,
    c.column_name,
    c.data_type,
    c.character_maximum_length,
    st.n_live_tup,
    pg_size_pretty(pg_total_relation_size(pc.oid)) as pretty_size
FROM
    information_schema.columns c
    JOIN pg_stat_all_tables st ON (st.schemaname = c.table_schema AND st.relname = c.table_name)
    JOIN pg_class pc ON (pc.relname = c.table_name)
    JOIN pg_namespace n ON (pc.relnamespace = n.oid AND n.nspname = c.table_schema)
WHERE
    table_schema NOT IN ('dbms_alert', 'dbms_assert', 'dbms_output', 'dbms_pipe', 'dbms_random', 'dbms_utility', 'information_schema', 'oracle', 'pg_catalog', 'pg_toast', 'plunit', 'plvchr', 'plvdate', 'plvlex', 'plvstr', 'plvsubst', 'utl_file')
    AND data_type NOT IN ('ARRAY', 'anyarray', 'bigint', 'boolean', 'bytea', 'double precision', 'inet', 'integer', 'interval', 'numeric', 'oid', 'pg_dependencies', 'pg_lsn', 'pg_ndistinct', 'pg_node_tree', 'real', 'regclass', 'regproc', 'regtype', 'smallint', 'timestamp with time zone', 'timestamp without time zone', 'xid')
	and c.table_catalog = current_database()
ORDER BY
    1,
    2,
    3;