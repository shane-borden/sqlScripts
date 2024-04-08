SELECT
    oid,
    s.schemaname,
    oid::regclass table_name,
    substr(unnest(reloptions), 1, strpos(unnest(reloptions), '=') - 1) option,
    substr(unnest(reloptions), 1 + strpos(unnest(reloptions), '=')) value
FROM
    pg_class c
    JOIN pg_stat_all_tables s ON (s.relid = c.oid)
WHERE
    reloptions IS NOT NULL
    AND (s.schemaname,
        s.relname) IN (
        SELECT
            t.table_schema,
            t.table_name
        FROM
            information_schema.tables t
            JOIN pg_catalog.pg_class c ON (t.table_name = c.relname)
            JOIN pg_catalog.pg_user u ON (c.relowner = u.usesysid)
        WHERE
            t.table_schema LIKE '%'
            AND u.usename LIKE '%'
            AND t.table_name LIKE '%'
            AND t.table_schema NOT IN ('information_schema', 'pg_catalog'));