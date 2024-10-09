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

WITH y AS (
    SELECT
        pg_catalog.format('%I.%I', n1.nspname, c1.relname) AS referencing_tbl,
        pg_catalog.quote_ident(a1.attname) AS referencing_column,
        t.conname AS existing_fk_on_referencing_tbl,
        pg_catalog.format('%I.%I', n2.nspname, c2.relname) AS referenced_tbl,
        pg_catalog.quote_ident(a2.attname) AS referenced_column,
        pg_relation_size(pg_catalog.format('%I.%I', n1.nspname, c1.relname)) AS referencing_tbl_bytes,
        pg_relation_size(pg_catalog.format('%I.%I', n2.nspname, c2.relname)) AS referenced_tbl_bytes,
        pg_catalog.format($$CREATE INDEX %I_idx ON %I.%I(%I);$$, t.conname, n1.nspname, c1.relname, a1.attname) AS suggestion
    FROM
        pg_catalog.pg_constraint t
        JOIN pg_catalog.pg_attribute a1 ON a1.attrelid = t.conrelid
            AND a1.attnum = t.conkey[1]
        JOIN pg_catalog.pg_class c1 ON c1.oid = t.conrelid
        JOIN pg_catalog.pg_namespace n1 ON n1.oid = c1.relnamespace
        JOIN pg_catalog.pg_class c2 ON c2.oid = t.confrelid
        JOIN pg_catalog.pg_namespace n2 ON n2.oid = c2.relnamespace
        JOIN pg_catalog.pg_attribute a2 ON a2.attrelid = t.confrelid
            AND a2.attnum = t.confkey[1]
    WHERE
        t.contype = 'f'
        AND NOT EXISTS (
            SELECT
                1
            FROM
                pg_catalog.pg_index i
            WHERE
                i.indrelid = t.conrelid
                AND i.indkey[0] = t.conkey[1]))
SELECT
    referencing_tbl,
    referencing_column,
    existing_fk_on_referencing_tbl,
    referenced_tbl,
    referenced_column,
    pg_size_pretty(referencing_tbl_bytes) AS referencing_tbl_size,
    pg_size_pretty(referenced_tbl_bytes) AS referenced_tbl_size,
    suggestion
FROM
    y
ORDER BY
    referencing_tbl_bytes DESC,
    referenced_tbl_bytes DESC,
    referencing_tbl,
    referenced_tbl,
    referencing_column,
    referenced_column;
