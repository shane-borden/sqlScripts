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