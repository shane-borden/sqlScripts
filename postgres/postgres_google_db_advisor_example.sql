/* Set AlloyDB Flag to have advisor run 1x per hour */
google_db_advisor.auto_advisor_schedule = 'EVERY 1 HOURS'

/* Check location of extensions */
(postgres@10.3.1.17:5432) [postgres] > \dx hypopg
      List of installed extensions
  Name  | Version | Schema | Description
--------+---------+--------+-------------
 hypopg | 1.3.2   | public |
 (postgres@10.3.1.17:5432) [postgres] > \dx google_db_advisor
            List of installed extensions
       Name        | Version | Schema | Description
-------------------+---------+--------+-------------
 google_db_advisor | 1.0     | public |

CREATE TABLE public.index_advisor_test (
		id int, 
		value numeric,
		product_id int,
		effective_date timestamp(3)
		);
INSERT INTO public.index_advisor_test VALUES ( 
		generate_series(0,100000000), 
		random()*1000,
		random()*100,
		current_timestamp(3));
		
CREATE SCHEMA idx_advisor;

CREATE TABLE idx_advisor.index_advisor_test (
		id int, 
		value numeric,
		product_id int,
		effective_date timestamp(3)
		);
INSERT INTO idx_advisor.index_advisor_test VALUES ( 
		generate_series(0,100000000), 
		random()*1000,
		random()*100,
		current_timestamp(3));

ANALYZE VERBOSE public.index_advisor_test;
ANALYZE VERBOSE idx_advisor.index_advisor_test;

/* Run a query that could possibly benefit from an index: */

SET enable_ultra_fast_cache_explain_output TO ON;
EXPLAIN (analyze, verbose, columnar_engine, costs, settings, buffers, wal, timing, summary, format text)
select /* INDEX ADVISOR TEST */ * from public.index_advisor_test where id = 500533;

EXPLAIN (analyze, verbose, columnar_engine, costs, settings, buffers, wal, timing, summary, format text)
select /* INDEX ADVISOR TEST */ * from idx_advisor.index_advisor_test where id = 500533;


/* Check index advisor las run */
SELECT DISTINCT recommended_indexes, query
FROM google_db_advisor_workload_report r, google_db_advisor_workload_statements s
WHERE r.query_id = s.query_id;

SELECT 
    r.recommended_indexes,
    s.query 
FROM
    google_db_advisor_workload_report r,
    google_db_advisor_workload_statements s
WHERE
    r.query_id = s.query_id
    AND r.db_id = s.db_id
    AND r.user_id = s.user_id
    AND length(r.recommended_indexes) > 0;

select * from google_db_advisor_workload_report_detail;



