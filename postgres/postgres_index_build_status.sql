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

-- Basis of script from https://wiki.postgresql.org/wiki/Index_Progress

select
  now(),
  query_start as started_at,
  now() - query_start as query_duration,
  format('[%s] %s', a.pid, a.query) as pid_and_query,
  index_relid::regclass as index_name,
  relid::regclass as table_name,
  (pg_size_pretty(pg_relation_size(relid))) as table_size,
  nullif(wait_event_type, '') || ': ' || wait_event as wait_type_and_event,
  phase,
  format(
    '%s (%s of %s)',
    coalesce((round(100 * blocks_done::numeric / nullif(blocks_total, 0), 2))::text || '%', 'N/A'),
    coalesce(blocks_done::text, '?'),
    coalesce(blocks_total::text, '?')
  ) as blocks_progress,
  format(
    '%s (%s of %s)',
    coalesce((round(100 * tuples_done::numeric / nullif(tuples_total, 0), 2))::text || '%', 'N/A'),
    coalesce(tuples_done::text, '?'),
    coalesce(tuples_total::text, '?')
  ) as tuples_progress,
  current_locker_pid,
  (select nullif(left(query, 150), '') || '...' from pg_stat_activity a where a.pid = current_locker_pid) as current_locker_query,
  format(
    '%s (%s of %s)',
    coalesce((round(100 * lockers_done::numeric / nullif(lockers_total, 0), 2))::text || '%', 'N/A'),
    coalesce(lockers_done::text, '?'),
    coalesce(lockers_total::text, '?')
  ) as lockers_progress,
  format(
    '%s (%s of %s)',
    coalesce((round(100 * partitions_done::numeric / nullif(partitions_total, 0), 2))::text || '%', 'N/A'),
    coalesce(partitions_done::text, '?'),
    coalesce(partitions_total::text, '?')
  ) as partitions_progress,
  (
    select
      format(
        '%s (%s of %s)',
        coalesce((round(100 * n_dead_tup::numeric / nullif(reltuples::numeric, 0), 2))::text || '%', 'N/A'),
        coalesce(n_dead_tup::text, '?'),
        coalesce(reltuples::int8::text, '?')
      )
    from pg_stat_all_tables t, pg_class tc
    where t.relid = p.relid and tc.oid = p.relid
  ) as table_dead_tuples
from pg_stat_progress_create_index p
left join pg_stat_activity a on a.pid = p.pid
order by p.index_relid;