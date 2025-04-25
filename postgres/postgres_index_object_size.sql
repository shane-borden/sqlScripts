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
    n.nspname AS schemaname,
    pgi.tablename AS tablename,
    c.oid::regclass::text AS index_name,
    pi.inhparent::regclass::text AS top_index_name,
    pg_total_relation_size(c.oid) AS size,
    pg_size_pretty(pg_total_relation_size(c.oid)) AS pretty_size
FROM
    pg_class c
    JOIN pg_namespace n ON c.relnamespace = n.oid
    JOIN pg_indexes pgi ON pgi.indexname = c.oid::regclass::text
        AND pgi.schemaname = n.nspname
    LEFT JOIN pg_inherits pi ON c.oid = pi.inhrelid
WHERE
    c.relkind IN ('i')
    AND (n.nspname NOT IN ('pg_toast')
        AND n.nspname LIKE '%')
    AND (c.oid::regclass::text LIKE '%'
        AND pi.inhparent::regclass::text LIKE '%')
ORDER BY
    4 NULLS LAST;