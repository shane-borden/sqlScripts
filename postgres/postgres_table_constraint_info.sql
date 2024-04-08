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
    tc.table_schema,
    tc.table_name,
    pgc.contype,
    string_agg(col.column_name, ', ') AS columns,
    tc.constraint_name,
    tc.enforced,
    pgc.convalidated
FROM
    information_schema.table_constraints tc
    JOIN pg_namespace nsp ON nsp.nspname = tc.constraint_schema
    JOIN pg_constraint pgc ON pgc.conname = tc.constraint_name
        AND pgc.connamespace = nsp.oid
        AND pgc.contype IN ('c', 'p', 'f')
    JOIN information_schema.columns col ON col.table_schema = tc.table_schema
        AND col.table_name = tc.table_name
        AND col.ordinal_position = ANY (pgc.conkey)
WHERE
    tc.constraint_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    pgc.contype,
    tc.enforced,
    pgc.convalidated
ORDER BY
    tc.table_schema,
    tc.table_name;