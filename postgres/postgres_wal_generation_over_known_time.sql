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

\prompt 'Enter sleep time: ' vSleepTime

SELECT
    *,
    pg_current_wal_lsn ()
FROM
    pg_stat_database
WHERE
    datname = current_database() \gset

select pg_sleep(:'vSleepTime');

SELECT
    blks_hit - :blks_hit "blk hit",
    blks_read - :blks_read "blk read",
    tup_inserted - :tup_inserted "ins",
    tup_updated - :tup_updated "upd",
    tup_deleted - :tup_deleted "del",
    tup_returned - :tup_returned "tup ret",
    tup_fetched - :tup_fetched "tup fch",
    xact_commit - :xact_commit "commit",
    xact_rollback - :xact_rollback "rbk",
    pg_size_pretty(pg_wal_lsn_diff (pg_current_wal_lsn (), :'pg_current_wal_lsn')) "WAL",
    pg_size_pretty(temp_bytes - :temp_bytes) "temp"
FROM
    pg_stat_database
WHERE
    datname = current_database();
