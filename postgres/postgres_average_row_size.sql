WITH table_size AS (
    SELECT
        c.relname AS table_name,
        pg_table_size(c.oid) AS main_table_size,
        pg_total_relation_size(c.oid) AS total_size,
        pg_total_relation_size(c.oid) - pg_table_size(c.oid) AS toast_size
    FROM pg_class c
    WHERE c.relname in ('packaged_events','media')
    AND c.relkind = 'r'
),
row_count AS (
    SELECT
        relname AS table_name,
        n_live_tup AS row_count
    FROM pg_stat_user_tables
    WHERE relname in ('packaged_events','media')
)
SELECT
    ts.table_name,
    ts.main_table_size,
    ts.toast_size,
    ts.total_size,
    COALESCE(rc.row_count, 1) AS row_count,
    (ts.total_size / NULLIF(rc.row_count, 0)) AS avg_row_size
FROM table_size ts
LEFT JOIN row_count rc ON ts.table_name = rc.table_name;
