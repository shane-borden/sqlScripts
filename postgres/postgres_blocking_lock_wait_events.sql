-- Copyright 2024 shaneborden
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     https://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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