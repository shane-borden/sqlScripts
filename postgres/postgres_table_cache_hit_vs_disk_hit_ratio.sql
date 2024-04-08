WITH all_tables AS (
    SELECT
        *
    FROM (
        SELECT
            'all'::text AS table_name,
            sum((coalesce(heap_blks_read, 0) + coalesce(idx_blks_read, 0) + coalesce(toast_blks_read, 0) + coalesce(tidx_blks_read, 0))) AS from_disk,
        sum((coalesce(heap_blks_hit, 0) + coalesce(idx_blks_hit, 0) + coalesce(toast_blks_hit, 0) + coalesce(tidx_blks_hit, 0))) AS from_cache
    FROM
        pg_statio_all_tables --> change to pg_statio_USER_tables if you want to check only user tables (excluding postgres's own tables)
) a
    WHERE (from_disk + from_cache) > 0 -- discard tables without hits
),
tables AS (
    SELECT
        *
    FROM (
        SELECT
            relname AS table_name,
            ((coalesce(heap_blks_read, 0) + coalesce(idx_blks_read, 0) + coalesce(toast_blks_read, 0) + coalesce(tidx_blks_read, 0))) AS from_disk,
        ((coalesce(heap_blks_hit, 0) + coalesce(idx_blks_hit, 0) + coalesce(toast_blks_hit, 0) + coalesce(tidx_blks_hit, 0))) AS from_cache
    FROM
        pg_statio_all_tables --> change to pg_statio_USER_tables if you want to check only user tables (excluding postgres's own tables)
) a
    WHERE (from_disk + from_cache) > 0 -- discard tables without hits
)
SELECT
    table_name AS "table name",
    from_disk AS "disk hits",
    round((from_disk::numeric / (from_disk + from_cache)::numeric) * 100.0, 2) AS "% disk hits",
    round((from_cache::numeric / (from_disk + from_cache)::numeric) * 100.0, 2) AS "% cache hits",
    (from_disk + from_cache) AS "total hits"
FROM (
    SELECT
        *
    FROM
        all_tables
    UNION ALL
    SELECT
        *
    FROM
        tables) a
ORDER BY
    (
        CASE WHEN table_name = 'all' THEN
            0
        ELSE
            1
        END),
    from_disk DESC;