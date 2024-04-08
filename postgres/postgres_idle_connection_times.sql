SELECT
    pid,usename,client_addr,current_timestamp - state_change time_in_idle,
    rank() over (partition by client_addr order by backend_start DESC) as rank
FROM
    pg_stat_activity
WHERE
    -- Exclude the thread owned connection (ie no auto-kill)
    pid <> pg_backend_pid( )
AND
    -- Exclude known applications connections
    application_name !~ '(?:psql)|(?:pgAdmin.+)'
AND
    -- Include connections to the same database the thread is connected to
    datname = current_database()
AND
    -- Include inactive connections only
    state in ('idle', 'idle in transaction', 'idle in transaction (aborted)', 'disabled')
AND
    -- Include old connections (found with the state_change field)
    current_timestamp - state_change > interval '5 minutes';