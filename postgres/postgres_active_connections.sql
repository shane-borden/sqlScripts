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
    pid,
    usename,
    state,
    client_addr,
    application_name,
    CURRENT_TIMESTAMP - state_change time_in_idle,
    rank() OVER (PARTITION BY client_addr ORDER BY backend_start DESC) AS rank
FROM
    pg_stat_activity
WHERE
-- Exclude the thread owned connection (ie no auto-kill)
pid <> pg_backend_pid()
    AND
    -- Exclude known applications connections
    application_name !~ '(?:pgAdmin.+)'
    AND
    -- Include connections to the same database the thread is connected to
    datname = current_database()
    AND
    -- Include inactive connections only
    state NOT IN ('idle', 'disabled');