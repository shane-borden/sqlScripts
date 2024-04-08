select
	round(EXTRACT(EPOCH FROM (clock_timestamp() - query_start))::numeric, 5) as query_age ,  
    round(EXTRACT(EPOCH FROM (clock_timestamp() -  xact_start))::numeric, 5) as xact_age,
	pid, 
	pg_blocking_pids(PID), 
	wait_event, 
	substr(query , 1, 80)
	query ,
	* 
	--,  pg_terminate_backend(PID)
from pg_stat_activity a,
		(select  unnest( string_to_array(replace(replace(pg_blocking_pids(PID)::text,'{',''),'}',''), ','))  as bpids, 
		         lower(query)   
		 from pg_stat_activity
		 --where lower(query) like '%drop%' or lower(query) like  '%alter%' 
		) b
where 
  PID = b.bpids::integer ;