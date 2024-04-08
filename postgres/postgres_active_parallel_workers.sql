SELECT
    current_setting('max_parallel_workers')::integer AS max_workers,
    count(*) AS active_workers
FROM
    pg_stat_activity
WHERE
    backend_type = 'parallel worker';