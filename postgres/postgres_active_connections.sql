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