/* Top SQL by Total Exec Time */
WITH
hist AS (
SELECT queryid::text,
       SUBSTRING(query from 1 for 100) query,
       ROW_NUMBER () OVER (ORDER BY total_exec_time::numeric DESC) rn,
       SUM(total_exec_time::numeric) total_exec_time
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
       total_exec_time::numeric
),
total AS (
SELECT SUM(total_exec_time::numeric) total_exec_time FROM hist
)
SELECT DISTINCT
       h.queryid::text,
       ROUND(h.total_exec_time::numeric,3) total_exec_time,
       ROUND(100 * h.total_exec_time / t.total_exec_time, 1) percent,
       h.query
  FROM hist h,
       total t
 WHERE h.total_exec_time >= t.total_exec_time / 1000 AND rn <= 14
 UNION ALL
SELECT 'Others',
       ROUND(COALESCE(SUM(h.total_exec_time::numeric), 0), 3) total_exec_time,
       COALESCE(ROUND(100 * SUM(h.total_exec_time) / AVG(t.total_exec_time), 1), 0) percent,
       NULL sql_text
  FROM hist h,
       total t
 WHERE h.total_exec_time < t.total_exec_time / 1000 OR rn > 14
 ORDER BY 3 DESC NULLS LAST;
