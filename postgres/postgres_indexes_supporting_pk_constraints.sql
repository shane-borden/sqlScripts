\prompt 'Enter schema_name: ' vSchemaName
SELECT
    n.nspname schema_name,
    c.conname constraint_name,
    c.contype constraint_type,
    i.relname index_name,
    t.relname table_name
FROM
    pg_constraint c
    JOIN pg_namespace n ON (c.connamespace = n.oid
            AND n.nspname = :'vSchemaName')
    JOIN pg_class i ON (c.conindid = i.oid)
    JOIN pg_class t ON (c.conrelid = t.oid)
WHERE
    c.contype = 'p';
