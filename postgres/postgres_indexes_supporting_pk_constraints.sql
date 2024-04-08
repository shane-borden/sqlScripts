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
