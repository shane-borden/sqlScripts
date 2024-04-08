WITH table_stats AS (
    SELECT
        schemaname,
        tablename,
        count(1) AS stats_count
    FROM
        pg_stats
    WHERE
        schemaname LIKE '%'
    GROUP BY
        schemaname,
        tablename
)
SELECT
    pt.schemaname AS schema_name,
    pt.tablename AS table_name,
    CASE WHEN pi.inhparent::text IS NULL THEN
        NULL
    ELSE
        pi.inhparent::regclass
    END AS top_table_name,
    pc.reltuples::numeric AS est_num_live_rows,
    ps.n_live_tup AS rows_in_stats,
    ps.n_tup_ins AS tot_num_inserts,
    ps.n_tup_upd AS tot_num_updates,
    ps.n_tup_del AS tot_num_deletes,
    ps.n_mod_since_analyze AS modified_rows,
    CASE WHEN pc.reltuples::numeric < 0 THEN
        100.00
    WHEN (ps.n_tup_ins + ps.n_tup_upd + ps.n_tup_del) = 0 THEN
        0.00
    WHEN ps.n_mod_since_analyze::numeric > 0
        AND pc.reltuples::numeric > 0 THEN
        CASE WHEN (ROUND((ps.n_mod_since_analyze / pc.reltuples)::numeric, 2) * 100) > 100 THEN
            100
        ELSE
            ROUND((ps.n_mod_since_analyze / pc.reltuples)::numeric, 2) * 100
        END
    WHEN ps.n_mod_since_analyze::numeric > 0
        AND pc.reltuples::numeric = 0 THEN
        ROUND((ps.n_mod_since_analyze / 1)::numeric, 2) * 100
    WHEN pc.reltuples = 0
        AND ps.n_live_tup = 0
        AND ps.n_mod_since_analyze = 0 THEN
        0.00
    ELSE
        ROUND((ps.n_live_tup / pc.reltuples)::numeric - 1, 2)
    END AS percent_stale,
    CASE WHEN ps.last_analyze IS NULL
        AND ps.last_autoanalyze IS NOT NULL THEN
        'Auto - ' || TO_CHAR(ps.last_autoanalyze, 'DD-MON-YY HH24:MI')
    WHEN ps.last_analyze IS NULL
        AND ts.stats_count IS NULL
        AND ps.last_autoanalyze IS NULL THEN
        'No Stats Available'
    WHEN ps.last_analyze IS NULL
        AND ts.stats_count > 0
        AND ps.last_autoanalyze IS NULL THEN
        'pg_stats - Status Unknown'
    WHEN ps.last_analyze IS NULL
        AND pc.reltuples > 0
        AND ps.last_autoanalyze IS NULL THEN
        'pg_class - Status Unknown'
    WHEN ps.last_analyze IS NOT NULL
        AND ps.last_autoanalyze IS NOT NULL
        AND (ps.last_autoanalyze > ps.last_analyze) THEN
        'Auto - ' || TO_CHAR(ps.last_autoanalyze, 'DD-MON-YY HH24:MI')
    ELSE
        'Manual - ' || TO_CHAR(ps.last_analyze, 'DD-MON-YY HH24:MI')
    END AS last_analyzed,
    CASE WHEN ps.last_vacuum IS NULL
        AND ps.last_autovacuum IS NOT NULL THEN
        'Auto - ' || TO_CHAR(ps.last_autovacuum, 'DD-MON-YY HH24:MI')
    WHEN ps.last_vacuum IS NOT NULL
        AND ps.last_autovacuum IS NULL THEN
        'Manual - ' || TO_CHAR(ps.last_vacuum, 'DD-MON-YY HH24:MI')
    WHEN ps.last_vacuum > ps.last_autovacuum THEN
        'Manual - ' || TO_CHAR(ps.last_vacuum, 'DD-MON-YY HH24:MI')
    ELSE
        'Auto - ' || TO_CHAR(ps.last_autovacuum, 'DD-MON-YY HH24:MI')
    END AS vacuum_status
FROM
    pg_tables pt
    JOIN pg_stat_all_tables ps ON ps.schemaname = pt.schemaname
        AND ps.relname = pt.tablename
    JOIN pg_class pc ON ps.relid = pc.oid
    LEFT JOIN pg_catalog.pg_inherits pi ON ps.relid = pi.inhrelid
    LEFT JOIN table_stats ts ON ts.schemaname = pt.schemaname
        AND ts.tablename = pt.tablename
WHERE
    pt.tablename LIKE '%'
ORDER BY
    3 NULLS LAST,
    1,
    2;