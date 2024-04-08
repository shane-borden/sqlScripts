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

/* Top SQL by Mean Exec Time */
WITH
hist AS (
SELECT queryid::text,
       SUBSTRING(query from 1 for 100) query,
       ROW_NUMBER () OVER (ORDER BY mean_exec_time::numeric DESC) rn,
       SUM(mean_exec_time::numeric) mean_exec_time
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
  		AND query::text not like 'DROP EXTENSION%'
  		AND query::text not like 'vacuum%'
  		AND query::text not like 'analyze%'
  		AND query::text not like 'COPY%'
  		AND query::text not like 'FETCH FORWARD%'
  		AND query::text not like '%shared_buffers_active%'
 GROUP BY
       queryid,
       SUBSTRING(query from 1 for 100),
       mean_exec_time::numeric
),
total AS (
SELECT SUM(mean_exec_time::numeric) mean_exec_time FROM hist
)
SELECT DISTINCT
       h.queryid::text,
       ROUND(h.mean_exec_time::numeric,3) mean_exec_time,
       ROUND(100 * h.mean_exec_time / t.mean_exec_time, 1) percent,
       h.query
  FROM hist h,
       total t
 WHERE h.mean_exec_time >= t.mean_exec_time / 1000 AND rn <= 14
 UNION ALL
SELECT 'Others',
       ROUND(COALESCE(SUM(h.mean_exec_time), 0), 3) mean_exec_time,
       COALESCE(ROUND(100 * SUM(h.mean_exec_time) / AVG(t.mean_exec_time), 1), 0) percent,
       NULL sql_text
  FROM hist h,
       total t
 WHERE h.mean_exec_time < t.mean_exec_time / 1000 OR rn > 14
 ORDER BY 3 DESC NULLS LAST;
