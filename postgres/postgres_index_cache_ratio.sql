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
	relname,
	indexrelname, 
	sum(idx_blks_read) as idx_read, 
	sum(idx_blks_hit)  as idx_hit, 
	ROUND((sum(idx_blks_hit) - sum(idx_blks_read)) / sum(idx_blks_hit),4) as ratio
FROM pg_statio_user_indexes
WHERE (idx_blks_read > 0 and idx_blks_hit > 0) AND relname like '%' AND indexrelname like '%'
GROUP BY 
	relname,
	indexrelname;