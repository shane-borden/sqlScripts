SELECT name, source, setting 
	FROM pg_settings  
	WHERE source != 'default' 
	AND source != 'override' 
	ORDER by 2, 1;