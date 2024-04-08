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

SELECT
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
                    count(distinct sql_exec_id) over(partition by sql_id) as exec_count,
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
                            ash.user_id,
                            du.username,
                            TO_CHAR(ash.sql_exec_start, 'YYYY-MM-DD HH24:MI:SS') AS sql_exec_start,
                            substr(TO_CHAR(ash.sample_time - ash.sql_exec_start, 'HH:MM:SS.FF'), - 12) AS sample_et,
                            MAX(  (EXTRACT(HOUR FROM ash.sample_time - ash.sql_exec_start) * 3600) +
                            (EXTRACT(MINUTE FROM ash.sample_time - ash.sql_exec_start) * 60) +
                            EXTRACT(SECOND FROM ash.sample_time - ash.sql_exec_start)) OVER(
                                PARTITION BY ash.instance_number, ash.sql_exec_id, ash.sql_id, ash.session_id
                            ) AS exec_et_secs,
                            ash.sample_time - lag(ash.sample_time) over( partition by ash.INSTANCE_NUMBER, session_id, session_serial# order by sample_time) as et_between_samples,
                            event,
                            wait_class,
                            seq#,
                            top_level_sql_id,
                            sql_plan_hash_value,
                            sql_plan_line_id,
                            sql_plan_operation,
                            sql_plan_options,
                            o.object_name,
                            MAX(ash.sample_time) OVER(
                                PARTITION BY ash.instance_number, ash.sql_exec_id, ash.sql_id,ash.session_id
                            ) AS max_sample,
                            client_id,
                            machine,
                            port,
                            session_id,
                            session_serial#,
                            ash.instance_number as inst_id,
                            blocking_session,
                            blocking_inst_id,
                            blocking_session_status,
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
                            substr(sq.sql_text, 1, 175) AS the_sql,
                            substr(tsql.sql_text, 1, 500) AS top_sql,
                            sq.EXACT_MATCHING_SIGNATURE,
                            sq.FORCE_MATCHING_SIGNATURE ,
                            blocking_hangchain_info,
                            current_obj#,
                            current_file#,
                            current_block#,
                            current_row#,
                            p1text,
                            p1,
                            p2text,
                            p2,
                            p3text,
                            p3
                        FROM
                            dba_hist_active_sess_history   ash
                            LEFT OUTER JOIN gv$sql         sq ON ash.sql_id = sq.sql_id
                                                              AND ash.instance_number = sq.inst_id
                                                              AND ash.sql_child_number = sq.child_number
                            LEFT OUTER JOIN (
                                SELECT DISTINCT
                                    sql_id,
                                     to_char(dbms_lob.substr(sql_text,70,1)) as  sql_text
                                FROM
                                    dba_hist_sqltext
                            ) tsql ON ash.top_level_sql_id = tsql.sql_id
                            LEFT OUTER JOIN dba_users du on du.user_id = ash.user_id
                            LEFT OUTER JOIN dba_objects o on o.object_id = ash.current_obj#
                            where  ash.sample_time BETWEEN   NVL(TO_DATE(:starttm, 'YYYY-MM-DD HH24:MI'), (SELECT MAX(sample_time)-(1/24) FROM dba_hist_active_sess_history)) AND NVL(TO_DATE(:endtm, 'YYYY-MM-DD HH24:MI'), (SELECT MAX(sample_time) FROM dba_hist_active_sess_history))
                            --and ash.module like 'smsclientengine%'
                            and tsql.sql_id in ('2r6qwm2aaaz0c')
                            --and ash.sql_id in('cpqu9tntjv392','cnjccdbsr30gw','57ctd87hnrhp3','1x9vq586h508p')
							--and upper(sq.sql_text) like 'WITH BILL_WINDOW_CYCLES AS%'
                            --and machine like 'gtlassoa%'
                            --and du.username='DWREP'
                    ) a
            ) b
)
/*ASHDATA*/
where nvl(the_sql,'x') not like 'SELECT /* ash_recent_sessions */%'
--and nvl(event,'x')='enq: TX - row lock contention'
--and nvl(event,'x')!='ges generic event'
--and nvl(module,'x') != 'DBMS_SCHEDULER'
--and (the_sql like '%SUPER%' )
--and module='SUPER'
--and module like 'SUPER%'
--and sql_id ='9zk77arubrvwm'  --dw87m1uqwdwp0
--and sql_id like '0ws0gj%'
--and the_sql like '%SUPER%'
--and sql_id in ('64x3rsjh1n6yg', '13nu1znn8cc1t','6ywzgz3nnpykd')
--and machine = 'SUPER'
--and upper(the_sql) like '%CI_ADJ%'
--and session_id= 8839
--and exec_et_secs >60
--and nvl(event,'x') not in ('library cache lock', 'cursor: pin S wait on X')
order by 1  ,2,3,4;