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
    relname,
    100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used,
    n_live_tup rows_in_table
FROM
    pg_stat_user_tables
WHERE (seq_scan + idx_scan) > 0
ORDER BY
    n_live_tup DESC;