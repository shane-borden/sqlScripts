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
    c.oid::regclass AS table_name,
    greatest (age(c.relfrozenxid), age(t.relfrozenxid)) AS "TXID age",
    (greatest (age(c.relfrozenxid), age(t.relfrozenxid))::numeric / 1000000000 * 100)::numeric(4, 2) AS "% WRAPAROUND RISK"
FROM
    pg_class c
    LEFT JOIN pg_class t ON c.reltoastrelid = t.oid
WHERE
    c.relkind IN ('r', 'm')
ORDER BY
    2 DESC;