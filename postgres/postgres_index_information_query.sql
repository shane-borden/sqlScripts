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
