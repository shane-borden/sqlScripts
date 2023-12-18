\prompt 'Enter relation name: ' vrelname

SELECT
    n.nspname,
    c.relname,
    c.relfilenode,
    c.oid,
    b.relblocknumber
FROM
    pg_buffercache b
    JOIN pg_class c ON b.relfilenode = pg_relation_filenode(c.oid)
        AND b.reldatabase IN (0, (
                SELECT
                    oid
                FROM pg_database
            WHERE
                datname = current_database()))
        JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relname = :'vrelname'
    ORDER BY
        5;
