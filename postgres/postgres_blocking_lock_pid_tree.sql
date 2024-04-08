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

WITH RECURSIVE activity AS (
    SELECT
        pg_blocking_pids (pid) blocked_by,
        *,
        age(clock_timestamp(), xact_start)::interval(0) AS tx_age,
        -- "pg_locks.waitstart" – PG14+ only; for older versions:  age(clock_timestamp(), state_change) as wait_age
        age(clock_timestamp(), (
            SELECT
                max(l.waitstart)
            FROM pg_locks l
            WHERE
                a.pid = l.pid))::interval(0) AS wait_age
    FROM
        pg_stat_activity a
    WHERE
        state IS DISTINCT FROM 'idle'
),
blockers AS (
    SELECT
        array_agg(DISTINCT c ORDER BY c) AS pids
    FROM (
        SELECT
            unnest(blocked_by)
        FROM
            activity) AS dt (c)
),
tree AS (
    SELECT
        activity.*,
        1 AS level,
        activity.pid AS top_blocker_pid,
        ARRAY[activity.pid] AS path,
        ARRAY[activity.pid]::int[] AS all_blockers_above
    FROM
        activity,
        blockers
    WHERE
        ARRAY[pid] <@ blockers.pids
        AND blocked_by = '{}'::int[]
    UNION ALL
    SELECT
        activity.*,
        tree.level + 1 AS level,
        tree.top_blocker_pid,
        path || ARRAY[activity.pid] AS path,
        tree.all_blockers_above || array_agg(activity.pid) OVER () AS all_blockers_above
    FROM
        activity,
        tree
    WHERE
        NOT ARRAY[activity.pid] <@ tree.all_blockers_above
        AND activity.blocked_by <> '{}'::int[]
        AND activity.blocked_by <@ tree.all_blockers_above
)
SELECT
    pid,
    blocked_by,
    CASE WHEN wait_event_type <> 'Lock' THEN
        replace(state, 'idle in transaction', 'idletx')
    ELSE
        'waiting'
    END AS state,
    wait_event_type || ':' || wait_event AS wait,
    wait_age,
    tx_age,
    to_char(age(backend_xid), 'FM999,999,999,990') AS xid_age,
    to_char(2147483647 - age(backend_xmin), 'FM999,999,999,990') AS xmin_ttf,
    datname,
    usename,
    (
        SELECT
            count(DISTINCT t1.pid)
        FROM
            tree t1
        WHERE
            ARRAY[tree.pid] <@ t1.path
            AND t1.pid <> tree.pid) AS blkd,
    format('%s %s%s', lpad('[' || pid::text || ']', 9, ' '), repeat('.', level -1) || CASE WHEN level > 1 THEN
            ' '
        END,
    LEFT (query, 1000)) AS query
FROM
    tree
ORDER BY
    top_blocker_pid,
    level,
    pid;