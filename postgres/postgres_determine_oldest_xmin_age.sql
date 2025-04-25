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
(SELECT max(age(backend_xmin)) FROM pg_stat_activity) as oldest_running_xact,
(SELECT max(age(transaction)) FROM pg_prepared_xacts) as oldest_prepared_xact,
(SELECT max(age(xmin)) FROM pg_replication_slots)     as oldest_replication_slot,
(SELECT max(age(backend_xmin)) FROM pg_stat_replication) as oldest_replica_xact
;