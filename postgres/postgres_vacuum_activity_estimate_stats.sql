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

WITH global_settings AS (
    -- Fetch global settings exactly once using pg_catalog.current_setting()
    -- The 'true' flag prevents errors on older PG versions missing certain settings (like insert_scale_factor)
    SELECT
        pg_catalog.current_setting('autovacuum_vacuum_insert_scale_factor', true)::numeric AS g_vac_ins_sf,
        pg_catalog.current_setting('autovacuum_vacuum_insert_threshold', true)::numeric AS g_vac_ins_th,
        pg_catalog.current_setting('autovacuum_vacuum_scale_factor', true)::numeric AS g_vac_sf,
        pg_catalog.current_setting('autovacuum_vacuum_threshold', true)::numeric AS g_vac_th,
        pg_catalog.current_setting('autovacuum_analyze_scale_factor', true)::numeric AS g_anl_sf,
        pg_catalog.current_setting('autovacuum_analyze_threshold', true)::numeric AS g_anl_th,
        pg_catalog.current_setting('autovacuum_freeze_max_age', true)::numeric AS g_freeze_max_age,
        pg_catalog.current_setting('autovacuum', true)::text AS g_autovac_enabled
)
SELECT
    pg_catalog.quote_ident(s.schemaname) || '.' || pg_catalog.quote_ident(s.relname) AS relname,
    s.n_live_tup AS live_tup,
    s.n_dead_tup AS dead_tup,
    s.n_tup_hot_upd AS hot_upd,
    s.n_mod_since_analyze AS mod_since_stats,
    s.n_ins_since_vacuum AS ins_since_vac,
    -- Threshold calculations using COALESCE (prioritizes local table setting, falls back to global)
    pg_catalog.ROUND((s.n_ins_since_vacuum * COALESCE(l.vac_ins_sf, g.g_vac_ins_sf)) + COALESCE(l.vac_ins_th, g.g_vac_ins_th), 0) AS ins_for_vac,
    pg_catalog.ROUND((s.n_live_tup * COALESCE(l.vac_sf, g.g_vac_sf)) + COALESCE(l.vac_th, g.g_vac_th), 0) AS mods_for_vac,
    pg_catalog.ROUND((s.n_live_tup * COALESCE(l.anl_sf, g.g_anl_sf)) + COALESCE(l.anl_th, g.g_anl_th), 0) AS mods_for_stats,
    -- Freeze metrics
    pg_catalog.ROUND((GREATEST(pg_catalog.age(c.relfrozenxid), pg_catalog.age(t.relfrozenxid))::numeric / COALESCE(l.freeze_max_age, g.g_freeze_max_age) * 100), 2) AS avac_pct_frz,
    GREATEST(pg_catalog.age(c.relfrozenxid), pg_catalog.age(t.relfrozenxid)) AS max_txid_age,
    CASE
        WHEN t.relfrozenxid IS NULL THEN 'Main Table (No TOAST)'
        WHEN pg_catalog.age(c.relfrozenxid) >= pg_catalog.age(t.relfrozenxid) THEN 'Main Table'
        ELSE 'TOAST Table'
    END AS max_txid_age_source,
    -- Timestamps and Intervals
    pg_catalog.to_char(s.last_vacuum, 'YYYY-MM-DD HH24:MI') AS last_vac,
    pg_catalog.to_char(s.last_analyze, 'YYYY-MM-DD HH24:MI') AS last_stats,
    pg_catalog.to_char(s.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_avac,
    pg_catalog.to_char(s.last_autoanalyze, 'YYYY-MM-DD HH24:MI') AS last_astats,
    (pg_catalog.now() - s.last_vacuum)::interval(0)::text AS time_since_vac,
    (pg_catalog.now() - s.last_analyze)::interval(0)::text AS time_since_stats,
    (pg_catalog.now() - s.last_autovacuum)::interval(0)::text AS time_since_avac,
    (pg_catalog.now() - s.last_autoanalyze)::interval(0)::text AS time_since_astats,
    -- Counters
    s.vacuum_count AS vac_cnt,
    s.analyze_count AS stats_cnt,
    s.autovacuum_count AS avac_cnt,
    s.autoanalyze_count AS astats_cnt,
    c.reloptions,
    COALESCE(l.autovacuum_enabled, g.g_autovac_enabled) AS autovac_enabled
FROM
    pg_stat_all_tables s
JOIN pg_class c ON s.relid = c.oid
LEFT JOIN pg_class t ON c.reltoastrelid = t.oid
CROSS JOIN global_settings g
-- Use a LATERAL join to extract local settings via regex. Much faster than 8 separate joins.
LEFT JOIN LATERAL (
    SELECT
        pg_catalog.substring(opts, 'autovacuum_vacuum_insert_scale_factor=([0-9.]+)')::numeric AS vac_ins_sf,
        pg_catalog.substring(opts, 'autovacuum_vacuum_insert_threshold=([0-9.]+)')::numeric AS vac_ins_th,
        pg_catalog.substring(opts, 'autovacuum_vacuum_scale_factor=([0-9.]+)')::numeric AS vac_sf,
        pg_catalog.substring(opts, 'autovacuum_vacuum_threshold=([0-9.]+)')::numeric AS vac_th,
        pg_catalog.substring(opts, 'autovacuum_analyze_scale_factor=([0-9.]+)')::numeric AS anl_sf,
        pg_catalog.substring(opts, 'autovacuum_analyze_threshold=([0-9.]+)')::numeric AS anl_th,
        pg_catalog.substring(opts, 'autovacuum_freeze_max_age=([0-9.]+)')::numeric AS freeze_max_age,
        pg_catalog.substring(opts, 'autovacuum_enabled=(true|false)')::text AS autovacuum_enabled
    FROM (SELECT pg_catalog.array_to_string(c.reloptions, ',') AS opts) AS o
) l ON true
ORDER BY
    1, 3;
