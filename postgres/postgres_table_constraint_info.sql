SELECT
    tc.table_schema,
    tc.table_name,
    pgc.contype,
    string_agg(col.column_name, ', ') AS columns,
    tc.constraint_name,
    tc.enforced,
    pgc.convalidated
FROM
    information_schema.table_constraints tc
    JOIN pg_namespace nsp ON nsp.nspname = tc.constraint_schema
    JOIN pg_constraint pgc ON pgc.conname = tc.constraint_name
        AND pgc.connamespace = nsp.oid
        AND pgc.contype IN ('c', 'p', 'f')
    JOIN information_schema.columns col ON col.table_schema = tc.table_schema
        AND col.table_name = tc.table_name
        AND col.ordinal_position = ANY (pgc.conkey)
WHERE
    tc.constraint_schema NOT IN ('pg_catalog', 'information_schema')
GROUP BY
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    pgc.contype,
    tc.enforced,
    pgc.convalidated
ORDER BY
    tc.table_schema,
    tc.table_name;