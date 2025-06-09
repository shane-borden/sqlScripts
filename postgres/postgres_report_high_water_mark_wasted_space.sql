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

CREATE EXTENSION pg_freespacemap;
 
CREATE OR REPLACE FUNCTION show_empty_pages(p_table_name TEXT)
RETURNS VOID AS $$
DECLARE
    -- Core processing variables
    table_oid_regclass  REGCLASS;
    block_size          BIGINT;
    fsm_granularity     BIGINT;
    max_fsm_free_space  BIGINT;
    total_pages         BIGINT;
    high_water_mark     BIGINT := 0;
 
    -- Variables for the final summary
    first_empty_block   BIGINT;
    free_pages_at_end   BIGINT;
    free_space_at_end   TEXT;
BEGIN
    -- Setup
    table_oid_regclass := p_table_name::regclass;
    block_size  := current_setting('block_size')::bigint;
    SELECT relpages INTO total_pages FROM pg_class WHERE oid = table_oid_regclass;
    fsm_granularity    := block_size / 256;
    max_fsm_free_space := floor((block_size - 24) / fsm_granularity) * fsm_granularity;
 
    --------------------------------------------------------------------------------
    -- PASS 1: FIND THE HIGH-WATER MARK (last page with data)
    --------------------------------------------------------------------------------
    FOR i IN REVERSE (total_pages - 1)..0 LOOP
        IF pg_freespace(table_oid_regclass, i) < max_fsm_free_space THEN
            high_water_mark := i;
            EXIT;
        END IF;
    END LOOP;
 
    --------------------------------------------------------------------------------
    -- FINAL STEP: CALCULATE AND RAISE THE SUMMARY NOTICE
    --------------------------------------------------------------------------------
    first_empty_block := high_water_mark + 1;
    free_pages_at_end := total_pages - first_empty_block;
    IF free_pages_at_end < 0 THEN
        free_pages_at_end := 0;
    END IF;
    free_space_at_end := pg_size_pretty(free_pages_at_end * block_size);
 
    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE 'Summary for table: %', p_table_name;
    RAISE NOTICE '-------------------------------------------------------------';
    RAISE NOTICE 'The High Water Mark (HWM) is at page: %', total_pages;
    IF total_pages <> first_empty_block THEN
        RAISE NOTICE 'First potentially empty page is at: %', first_empty_block;
        RAISE NOTICE 'Total Pages in Table: %', total_pages;
        RAISE NOTICE 'Number of potentially truncatable pages at the end: %', free_pages_at_end;
        RAISE NOTICE 'Amount of free space at the end of the table: %', free_space_at_end;
    ELSE
        RAISE NOTICE 'There are no empty pages to truncate';
    END IF;
    RAISE NOTICE '-------------------------------------------------------------';
END;
$$ LANGUAGE plpgsql;
