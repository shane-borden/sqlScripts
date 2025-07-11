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
WHERE table_schema = 'public'
AND table_name like '%'
AND total_bytes > 0
ORDER BY total_bytes DESC;
