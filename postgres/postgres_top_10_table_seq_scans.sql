SELECT
    relid,
    relname,
    seq_scan,
    pg_size_pretty(pg_relation_size(relid))
FROM
    pg_stat_user_tables
ORDER BY
    seq_scan DESC
LIMIT 10;
