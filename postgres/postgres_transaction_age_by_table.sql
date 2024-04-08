SELECT
    c.oid::regclass AS table_name,
    greatest (age(c.relfrozenxid), age(t.relfrozenxid)) AS "TXID age",
    (greatest (age(c.relfrozenxid), age(t.relfrozenxid))::numeric / 1000000000 * 100)::numeric(4, 2) AS "% WRAPAROUND RISK"
FROM
    pg_class c
    LEFT JOIN pg_class t ON c.reltoastrelid = t.oid
WHERE
    c.relkind IN ('r', 'm')
ORDER BY
    2 DESC;