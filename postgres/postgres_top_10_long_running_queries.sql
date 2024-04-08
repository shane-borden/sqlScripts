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

SELECT pid, age(backend_xid) AS age_in_xids, 
    now () - xact_start AS xact_age, 
    now () - query_start AS query_age, 
    state, 
    query 
    FROM pg_stat_activity 
    WHERE state != 'idle' 
    ORDER BY 2 DESC 
    LIMIT 10;