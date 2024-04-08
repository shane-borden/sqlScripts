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

SELECT
    oid,
    s.schemaname,
    oid::regclass table_name,
    substr(unnest(reloptions), 1, strpos(unnest(reloptions), '=') - 1) option,
    substr(unnest(reloptions), 1 + strpos(unnest(reloptions), '=')) value
FROM
    pg_class c
    JOIN pg_stat_all_tables s ON (s.relid = c.oid)
WHERE
    reloptions IS NOT NULL
    AND (s.schemaname,s.relname) IN (
        SELECT
            t.table_schema,
            t.table_name
        FROM
            information_schema.tables t
            JOIN pg_catalog.pg_class c ON (t.table_name = c.relname)
            JOIN pg_catalog.pg_user u ON (c.relowner = u.usesysid)
        WHERE
            t.table_schema LIKE '%'
            AND u.usename LIKE '%'
            AND t.table_name LIKE '%'
            AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
);
