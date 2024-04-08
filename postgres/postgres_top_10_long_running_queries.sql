SELECT pid, age(backend_xid) AS age_in_xids, 
    now () - xact_start AS xact_age, 
    now () - query_start AS query_age, 
    state, 
    query 
    FROM pg_stat_activity 
    WHERE state != 'idle' 
    ORDER BY 2 DESC 
    LIMIT 10;