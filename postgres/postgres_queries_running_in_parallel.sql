SELECT query, leader_pid,
  array_agg(pid) filter(WHERE leader_pid != pid) AS members
FROM pg_stat_activity
WHERE leader_pid IS NOT NULL
GROUP BY query, leader_pid;