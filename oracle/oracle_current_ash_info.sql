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

set lines 180
set pages 1000
alter session set nls_date_format = 'YYYY-MM-DD HH24:MI:SS';
alter session set nls_timestamp_format = 'YYYY-MM-DD HH24:MI:SS.FF';
-- Show activity for recent sessions.  Uses gv$active_session_history, so only recent data available.
-- Requires license for Tuning and Diagnostics
-- Defaults to activity within the last 2 minutes if start_time and end_time parameters are NULL
-- Parameter format is 'YYYY-MM-DD HH24:MI'
SELECT /* ash_recent_sessions */
    *
FROM
    (
        SELECT
            b.*
        FROM
            (
                SELECT
                    a.*,
                    round(avg(exec_et_secs) over(
                        PARTITION BY sql_id
                    ),2) AS avg_exec,
                    MIN(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ) AS min_exec,
                    MAX(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ) AS max_exec,
                    round(STDDEV(exec_et_secs) OVER(
                        PARTITION BY sql_id
                    ),2) AS stddev,
                    count(distinct sql_exec_id) over(partition by inst_id, session_id, SESSION_SERIAL#, sql_id) as exec_count,
                    count(distinct SQL_PLAN_HASH_VALUE) over (partition by sql_id) as plan_hash_count,
                    round(avg(exec_et_secs) OVER (partition by sql_plan_hash_value),2) as avg_plan_exec_et,
                    min(sample_time) over(partition by sql_id) as first_exec,
                    max(sample_time) over(partition by sql_id) as last_exec
                FROM
                    (
                        SELECT
                            ash.sample_time,
                            TO_CHAR(ash.sample_time, 'YYYY-MM-DD HH24:MI:SS') AS sample_time_char,
                            ash.sql_exec_id,
                            ash.sql_id,
                            ash.sql_child_number,
                            ash.program,
                            ash.module,
                            ash.action,
                            ash.session_type,
                            ash.user_id,
                            du.username,
                            ash.client_id,
                            gs.resource_consumer_group,
                            TO_CHAR(ash.sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') AS sql_exec_start,
                            substr(TO_CHAR(ash.sample_time - ash.sql_exec_start, 'HH:MM:SS.FF'), - 12) AS sample_et,
                            MAX(  (EXTRACT(HOUR FROM ash.sample_time - ash.sql_exec_start) * 3600) +
                            (EXTRACT(MINUTE FROM ash.sample_time - ash.sql_exec_start) * 60) +
                            EXTRACT(SECOND FROM ash.sample_time - ash.sql_exec_start)) OVER(
                                PARTITION BY ash.inst_id, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS exec_et_secs,
                            -- Use ET_Between_Samples to help identify when a connection has been idle for a while.
                            -- This is the elapsed time between samples for the connection.
                            ash.sample_time - lag(ash.sample_time) over( partition by ash.inst_id, ash.session_id, ash.session_serial# order by ash.sample_time) as et_between_samples,
                            tm_delta_time,
                            tm_delta_cpu_time,
                            tm_delta_db_time,
                            (tm_delta_cpu_time/10000)+tm_delta_db_time as tot_time,
                            tm_delta_time - tm_delta_db_time as diftime,
                            ash.event,
                            ash.wait_class,
                            ash.inst_id,
                            ash.session_id,
                            ash.SESSION_SERIAL#,
                            ash.ecid,
                            ash.seq#,
                            top_level_sql_id,
                            sql_plan_hash_value,
                            sql_plan_line_id,
                            sql_plan_operation,
                            sql_plan_options,
                            o.owner,
                            o.object_name,
                            o.subobject_name,
                            o.object_type,
                            MAX(ash.sample_time) OVER(
                                PARTITION BY ash.inst_id, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS max_sample,
                            --client_id,
                            ash.machine,
                            ash.port,
                            ash.blocking_session,
                            ash.blocking_inst_id,
                            ash.blocking_session_status,
                            in_connection_mgmt,
                            in_parse,
                            in_hard_parse,
                            in_sql_execution,
                            in_plsql_execution,
                            in_plsql_rpc,
                            in_plsql_compilation,
                            in_java_execution,
                            in_bind,
                            in_cursor_close,
                            in_sequence_load,
                            sq.sql_text as the_sql,
                            tsql.sql_text as top_sql,
                            sq.EXACT_MATCHING_SIGNATURE,
                            sq.FORCE_MATCHING_SIGNATURE ,
                            ash.blocking_hangchain_info,
                            ash.current_obj#,
                            ash.current_file#,
                            ash.current_block#,
                            ash.current_row#,
                            ash.p1text,
                            ash.p1,
                            ash.p2text,
                            ash.p2,
                            ash.p3text,
                            ash.p3
                        FROM
                            gv$active_session_history   ash
                            LEFT OUTER JOIN gv$sql                      sq ON ash.sql_id = sq.sql_id
                                                         AND ash.inst_id = sq.inst_id
                                                         AND ash.sql_child_number = sq.child_number
                            LEFT OUTER JOIN (
                                SELECT DISTINCT
                                    sql_id,
                                    dbms_lob.substr(sql_text,75,1) as sql_text
                                FROM
                                    gv$sql
                            ) tsql ON ash.top_level_sql_id = tsql.sql_id
                            LEFT OUTER JOIN dba_users du on du.user_id = ash.user_id
                            LEFT OUTER JOIN dba_objects o on o.object_id = ash.current_obj#
                            LEFT OUTER JOIN gv$session gs on gs.inst_id = ash.inst_id and gs.sid = ash.session_id and gs.serial# = ash.session_serial#
                            where  ash.sample_time BETWEEN nvl(TO_DATE(:starttm, 'YYYY-MM-DD HH24:MI'), sysdate-(1/24/30)) AND nvl(TO_DATE(:endtm, 'YYYY-MM-DD HH24:MI'), sysdate)
                            and nvl(ash.event, 'x') != 'ges generic event'
/* Add filters here */
                            and ash.sql_id in ( '2r6qwm2aaaz0c' )
--                            and ash.machine like 'EXA%'
--                            and ash.sql_plan_hash_value = 534356389
--                            and upper(sq.sql_text) like 'UPDATE%'
--                            and du.username = 'CA12345'
--                            and ash.module like 'SUPER%'
--                            and ash.client_id = 'SUPER'
--                            and nvl(event,'x') = 'enq: TX - row lock contention'
                    ) a
            ) b
)
where nvl(the_sql,'x') not like 'SELECT /* ash_recent_sessions */%'
--and exec_et_secs >3600
--and module !='GoldenGate'
order by sample_time desc
/