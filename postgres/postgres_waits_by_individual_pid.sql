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