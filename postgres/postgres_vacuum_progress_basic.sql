/* Basic Vacuum Progress */
SELECT
    pid,
    datname,
    relid::regclass relname,
    phase,
    heap_blks_total,
    heap_blks_scanned,
    heap_blks_vacuumed,
    index_vacuum_count,
    max_dead_tuples,
    num_dead_tuples
FROM
    pg_stat_progress_vacuum;
