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

\prompt 'Enter PID to check: ' pidvar
SELECT
    pid,
    usename,
    application_name,
    TO_CHAR(backend_start, 'YYYY-MM-DD HH24:MI') AS backend_start,
    TO_CHAR(xact_start, 'YYYY-MM-DD HH24:MI:SS') AS xact_start,
    TO_CHAR(query_start, 'YYYY-MM-DD HH24:MI:SS') AS query_start,
    TO_CHAR(state_change, 'YYYY-MM-DD HH24:MI') AS state_change,
    wait_event_type,
    wait_event,
    state,
    query_id,
    query
FROM
    pg_stat_activity
WHERE
    pid = :'pidvar';

\watch 1