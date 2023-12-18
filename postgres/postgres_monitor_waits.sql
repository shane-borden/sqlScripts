\prompt 'Enter PID to check: ' pidvar
select 
  pid, 
  usename, 
  application_name, 
  TO_CHAR(
    backend_start, 'YYYY-MM-DD HH24:MI') as backend_start, 
  TO_CHAR(
    xact_start, 'YYYY-MM-DD HH24:MI:SS') as xact_start, 
  TO_CHAR(
    query_start, 'YYYY-MM-DD HH24:MI:SS') as query_start, 
  TO_CHAR(
    state_change, 'YYYY-MM-DD HH24:MI') as state_change, 
  wait_event_type, 
  wait_event, 
  state, 
  query_id, 
  query 
from 
  pg_stat_activity 
where 
  pid = :'pidvar';

\watch 1
