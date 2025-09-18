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

/* Vaccum Stats Script */

WITH tbl_reloptions AS (
SELECT
	oid,
    oid::regclass table_name,
    substr(unnest(reloptions), 1,  strpos(unnest(reloptions), '=') -1) option,
    substr(unnest(reloptions), 1 + strpos(unnest(reloptions), '=')) value
FROM
    pg_class c
WHERE reloptions is NOT null)
SELECT
    --to_char(now(), 'YYYY-MM-DD HH:MI'),
    current_database() ||'.'|| s.schemaname ||'.'|| s.relname as relname,
    n_live_tup live_tup,
    n_dead_tup dead_dup,
    n_tup_hot_upd hot_upd,
    n_mod_since_analyze mod_since_stats,
    n_ins_since_vacuum ins_since_vac,
    case 
	  when avacinsscalefactor.value is not null and avacinsthresh.value is not null
        then ROUND(((n_live_tup * avacinsscalefactor.value::numeric) + avacinsthresh.value::numeric),0)
      when avacinsscalefactor.value is null and avacinsthresh.value is not null
      	then ROUND(((n_live_tup * (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_insert_scale_factor')) + avacinsthresh.value::numeric),0)
      when avacinsscalefactor.value is not null and avacinsthresh.value is null
      	then ROUND(((n_live_tup * avacinsscalefactor.value::numeric) + (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_insert_threshold')),0)
      else ROUND(((n_live_tup * (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_insert_scale_factor')) + (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_insert_threshold')),0) 
    end as ins_for_vac,
    case 
	  when avacscalefactor.value is not null and avacthresh.value is not null
        then ROUND(((n_live_tup * avacscalefactor.value::numeric) + avacthresh.value::numeric),0)
      when avacscalefactor.value is null and avacthresh.value is not null
      	then ROUND(((n_live_tup * (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_scale_factor')) + avacthresh.value::numeric),0)
      when avacscalefactor.value is not null and avacthresh.value is null
      	then ROUND(((n_live_tup * avacscalefactor.value::numeric) + (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_threshold')),0)
      else ROUND(((n_live_tup * (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_scale_factor')) + (select setting::numeric from pg_settings where name = 'autovacuum_vacuum_threshold')),0) 
    end as mods_for_vac,
    case 
	  when avacanalyzescalefactor.value is not null and avacanalyzethresh.value is not null
        then ROUND(((n_live_tup * avacanalyzescalefactor.value::numeric) + avacanalyzethresh.value::numeric),0)
      when avacanalyzescalefactor.value is null and avacanalyzethresh.value is not null
      	then ROUND(((n_live_tup * (select setting::numeric from pg_settings where name = 'autovacuum_analyze_scale_factor')) + avacanalyzethresh.value::numeric),0)
      when avacanalyzescalefactor.value is not null and avacanalyzethresh.value is null
      	then ROUND(((n_live_tup * avacanalyzescalefactor.value::numeric) + (select setting::numeric from pg_settings where name = 'autovacuum_analyze_threshold')),0)
      else ROUND(((n_live_tup * (select setting::numeric from pg_settings where name = 'autovacuum_analyze_scale_factor')) + (select setting::numeric from pg_settings where name = 'autovacuum_analyze_threshold')),0) 
    end as mods_for_stats,
    case 
      when avacfreezeage is not null
        then ROUND((greatest(age(c.relfrozenxid),age(t.relfrozenxid))::numeric / avacfreezeage.value::numeric * 100),2) 
      else ROUND((greatest(age(c.relfrozenxid),age(t.relfrozenxid))::numeric / (select setting::numeric from pg_settings where name = 'autovacuum_freeze_max_age') * 100),2) 
      end as avac_pct_frz,
    greatest(age(c.relfrozenxid),age(t.relfrozenxid)) max_txid_age,
    to_char(last_vacuum, 'YYYY-MM-DD HH24:MI') last_vac,
    to_char(last_analyze, 'YYYY-MM-DD HH24:MI') last_stats,
    to_char(last_autovacuum, 'YYYY-MM-DD HH24:MI') last_avac,
    to_char(last_autoanalyze, 'YYYY-MM-DD HH24:MI') last_astats,
    vacuum_count vac_cnt,
    analyze_count stats_cnt,
    autovacuum_count avac_cnt,
    autoanalyze_count astats_cnt,
    c.reloptions,
    case
      when avacenabled.value is not null
        then avacenabled.value::text
      when (select setting::text from pg_settings where name = 'autovacuum') = 'on'
        then 'true'
      else 'false'
    end as autovac_enabled
FROM
    pg_stat_all_tables s
JOIN pg_class c ON (s.relid = c.oid)
LEFT JOIN pg_class t ON c.reltoastrelid = t.oid
LEFT JOIN tbl_reloptions avacinsscalefactor on (s.relid = avacinsscalefactor.oid and avacinsscalefactor.option = 'autovacuum_vacuum_insert_scale_factor')
LEFT JOIN tbl_reloptions avacinsthresh on (s.relid = avacinsthresh.oid and avacinsthresh.option = 'autovacuum_vacuum_insert_threshold')
LEFT JOIN tbl_reloptions avacscalefactor on (s.relid = avacscalefactor.oid and avacscalefactor.option = 'autovacuum_vacuum_scale_factor')
LEFT JOIN tbl_reloptions avacthresh on (s.relid = avacthresh.oid and avacthresh.option = 'autovacuum_vacuum_threshold')
LEFT JOIN tbl_reloptions avacanalyzescalefactor on (s.relid = avacanalyzescalefactor.oid and avacanalyzescalefactor.option = 'autovacuum_analyze_scale_factor')
LEFT JOIN tbl_reloptions avacanalyzethresh on (s.relid = avacanalyzethresh.oid and avacanalyzethresh.option = 'autovacuum_analyze_threshold')
LEFT JOIN tbl_reloptions avacfreezeage on (s.relid = avacfreezeage.oid and avacfreezeage.option = 'autovacuum_freeze_max_age')
LEFT JOIN tbl_reloptions avacenabled on (s.relid = avacenabled.oid and avacenabled.option = 'autovacuum_enabled')
WHERE
    s.relname IN (
        SELECT
            t.table_name
		FROM
    		information_schema.tables t
    		JOIN pg_catalog.pg_class c ON (t.table_name = c.relname)
    		LEFT JOIN pg_catalog.pg_user u ON (c.relowner = u.usesysid)
        WHERE
            t.table_schema like '%'
            AND (u.usename like '%' OR u.usename is null)
            AND t.table_name like '%'
            AND t.table_schema not in ('information_schema','pg_catalog')
            AND t.table_type not in ('VIEW')
			AND t.table_catalog = current_database())
    --AND n_dead_tup >= 0
    --AND n_live_tup > 0
ORDER BY 3;
