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

/* Rank Wait Events */
with
waits AS (
SELECT wait_event,
       rank() OVER (ORDER BY count(wait_event) DESC) rn
  FROM pg_stat_activity
 WHERE wait_event IS NOT NULL 
 GROUP BY
       wait_event
 order by count(wait_event) asc
),
total AS (
SELECT SUM(rn) total_waits FROM waits
)
SELECT DISTINCT
       h.wait_event,
       h.rn,
       ROUND(100 * h.rn / t.total_waits, 1) percent
  FROM waits h,
       total t
 WHERE h.rn >= t.total_waits / 1000 AND rn <= 14
 UNION ALL
SELECT 'Others',
       COALESCE(SUM(h.rn), 0) rn,
       COALESCE(ROUND(100 * SUM(h.rn) / AVG(t.total_waits), 1), 0) percent
  FROM waits h,
       total t
 WHERE h.rn < t.total_waits / 1000 OR rn > 14
 ORDER BY 2 DESC NULLS LAST;