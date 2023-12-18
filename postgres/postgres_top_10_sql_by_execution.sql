WITH
hist AS (
SELECT queryid::text,
       SUBSTRING(query from 1 for 100) query,
       ROW_NUMBER () OVER (ORDER BY calls DESC) rn,
       calls
  FROM pg_stat_statements 
 WHERE queryid IS NOT NULL 
 		AND query::text not like '%pg_%' 
 		AND query::text not like '%g_%'
 		AND query::text not like '%heartbeat%'
  		AND query::text not like '%SELECT $1%'
  		AND query::text not like '%google_%'
  		AND query::text not like 'SELECT txid_current%'
  		AND query::text not like 'CREATE TEMPORARY TABLE%'
  		AND query::text not like 'EXPLAIN%'
  		AND query::text not like 'vacuum%'
  		AND query::text not like 'analyze%'
 GROUP BY
       queryid,
       SUBSTRING(query from 1 for 100),
       calls
),
total AS (
SELECT SUM(calls) calls FROM hist
)
SELECT DISTINCT
       h.queryid::text,
       h.calls,
       ROUND(100 * h.calls / t.calls, 1) percent,
       h.query
  FROM hist h,
       total t
 WHERE h.calls >= t.calls / 1000 AND rn <= 14
 UNION ALL
SELECT 'Others',
       COALESCE(SUM(h.calls), 0) calls,
       COALESCE(ROUND(100 * SUM(h.calls) / AVG(t.calls), 1), 0) percent,
       NULL sql_text
  FROM hist h,
       total t
 WHERE h.calls < t.calls / 1000 OR rn > 14
 ORDER BY 2 DESC NULLS LAST;
