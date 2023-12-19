SELECT
    c.relname AS relname,
    pg_size_pretty(sum(pg_relation_size(idx))::bigint) AS size,
    (array_agg(idx))[1] AS idx1,
    (array_agg(idx))[2] AS idx2,
    (array_agg(idx))[3] AS idx3,
    (array_agg(idx))[4] AS idx4
FROM (
    SELECT
        indrelid,
        indexrelid::regclass AS idx,
        (indrelid::text || E'\n' || indclass::text || E'\n' || indkey::text || E'\n' || coalesce(indexprs::text, '') || E'\n' || coalesce(indpred::text, '')) AS key
    FROM
        pg_index) sub
    JOIN pg_class c ON (c.oid = sub.indrelid)
GROUP BY
    relname,
    key
HAVING
    count(*) > 1
ORDER BY
    sum(pg_relation_size(idx)) DESC;
