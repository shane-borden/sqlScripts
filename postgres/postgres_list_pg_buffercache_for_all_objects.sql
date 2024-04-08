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
    n.nspname,
    c.relname,
    count(*) AS buffers
FROM
    pg_buffercache b
    JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
        AND b.reldatabase IN (0, (
                SELECT
                    oid
                FROM pg_database
            WHERE
                datname = current_database()))
        JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE
        n.nspname = 'public'
    GROUP BY
        n.nspname,
        c.relname
    ORDER BY
        3 DESC;
