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

/* Determine which pids map to the oldest xmin age */
SELECT
    pid,
    usename,
    datname,
    client_addr,
    state,
    now() - backend_start connection_total_time,
    now() - state_change time_in_state,
    now() - xact_start time_in_xact,
    now() - query_start time_in_query,
    wait_event,
    left (query, 40),
    max(age(backend_xmin))
FROM
    pg_stat_activity
WHERE
    1=1
    AND backend_xmin IS NOT NULL
GROUP BY
    pid,
    usename,
    datname,
    client_addr,
    state,
    now() - backend_start,
    now() - state_change,
    now() - xact_start,
    now() -  query_start,
    wait_event,
    left (query, 40)
ORDER BY
    max(age(backend_xmin)) DESC;