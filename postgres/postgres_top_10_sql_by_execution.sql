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

WITH
hist AS (
SELECT queryid::text,
       SUBSTRING(query from 1 for 100) query,
       ROW_NUMBER () OVER (ORDER BY calls DESC) rn,
       calls
  FROM pg_stat_statements 
 WHERE queryid IS NOT NULL 
 		AND query::text not like '%pg_%' 
 		AND query::text not like '%g_%'
 		AND query::text not like '%heartbeat%'
  		AND query::text not like '%SELECT $1%'
  		AND query::text not like '%google_%'
  		AND query::text not like 'SELECT txid_current%'
  		AND query::text not like 'CREATE TEMPORARY TABLE%'
  		AND query::text not like 'EXPLAIN%'
  		AND query::text not like 'vacuum%'
  		AND query::text not like 'analyze%'
 GROUP BY
       queryid,
       SUBSTRING(query from 1 for 100),
       calls
),
total AS (
SELECT SUM(calls) calls FROM hist
)
SELECT DISTINCT
       h.queryid::text,
       h.calls,
       ROUND(100 * h.calls / t.calls, 1) percent,
       h.query
  FROM hist h,
       total t
 WHERE h.calls >= t.calls / 1000 AND rn <= 14
 UNION ALL
SELECT 'Others',
       COALESCE(SUM(h.calls), 0) calls,
       COALESCE(ROUND(100 * SUM(h.calls) / AVG(t.calls), 1), 0) percent,
       NULL sql_text
  FROM hist h,
       total t
 WHERE h.calls < t.calls / 1000 OR rn > 14
 ORDER BY 2 DESC NULLS LAST;
