# Postgres SQL Scripts - Shorthand Commands from PSQL

[//]: # (Original Layout for this Readme.md was from https://gist.github.com/apolloclark)

## Use of .psqlrc
The .psqlrc file allows you to configure personalized settings, add shortcuts and add custom commands.  It is stored in the users home directory and will automatically be read upon launch of `psql`.

An example of a .psqlrc file can be found here:
 - <a href="https://github.com/shane-borden/sqlScripts/blob/master/postgres/.psqlrc">Sample .psqlrc file</a> for example .psqlrc content.

##### Ignore .psqlrc
```sql
psql --username=<username> --dbname=<database> --host=<hostname> --port=<port> --no-psqlrc
```

<br/>

## General psql navigation
##### Connect
Password can be exported at the command line by using:
```bash
export PGPASSWORD=<somepassword>
```
General connections can be made using:
```sql
psql -U <username> -d <database> -h <hostname> -p <port>

psql --username=<username> --dbname=<database> --host=<hostname> --port=<port>

psql -U <username> -d <database> -h <host> -f <local_file>

psql --username=<username> --dbname=<database> --host=<host> --file=<local_file>
```

##### Disconnect
```sql
\q
\!
```

##### Clear scrollback
```sql
(CTRL + L)
```

##### Set Resultset to "Unaligned"
```sql
\a
```

##### Set Resultset to "Extended"
```sql
\x
```
<br/>

## Information about the connected system

##### Server version
```
SHOW SERVER_VERSION;
```

##### Show connection information (SSL USED? PSQL VERSION?)
```sql
\conninfo
```

##### Show environment variables
```sql
SHOW ALL;
```

##### List all roles in the instance
```sql
SELECT rolname FROM pg_roles;
```

##### Show currently connected user
```sql
SELECT current_user;
```

##### Show current user permissions
```sql
\du
\du+
```

##### Show current user's session settings
```sql
\drds
```

##### show current database
```sql
SELECT current_database();
```

##### show all tables in database
```sql
\dt
\dt+
```

##### list functions
```sql
\df <schema>
\df+ <schema>
```
<br/>

## Databases

##### list databases with size information
```sql
\l
\l+
```

##### Connect to database
```sql
\c <database_name>
```

##### Connect to database as different user
```sql
\c <database_name> <username>
```

<br/>

## Users

##### create user
http://www.postgresql.org/docs/current/static/sql-createuser.html
```sql
CREATE USER <user_name> WITH PASSWORD '<password>';
```

##### drop user
http://www.postgresql.org/docs/current/static/sql-dropuser.html
```sql
DROP USER IF EXISTS <user_name>;
```

##### alter user password
http://www.postgresql.org/docs/current/static/sql-alterrole.html
```sql
ALTER ROLE <user_name> WITH PASSWORD '<password>';
```
<br/>

## Permissions

##### Grant all permissions on database
http://www.postgresql.org/docs/current/static/sql-grant.html
```sql
GRANT ALL PRIVILEGES ON DATABASE <db_name> TO <user_name>;
```

##### Grant connect permission on database
```sql
GRANT CONNECT ON DATABASE <db_name> TO <user_name>;
```

##### Grant individual permissions on schema
```sql
GRANT USAGE ON SCHEMA public TO <user_name>;
```

##### Grant permissions to functions
```sql
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO <user_name>;
```

##### Grant permissions to select, update, insert, delete, on all tables in a schema
```sql
GRANT SELECT, UPDATE, INSERT ON ALL TABLES IN SCHEMA public TO <user_name>;
```

##### Grant all permissions on an individual table
```sql
GRANT SELECT, UPDATE, INSERT ON <table_name> TO <user_name>;
```

##### Grant a single permission on an individual table
```sql
GRANT SELECT ON ALL TABLES IN SCHEMA public TO <user_name>;
```
<br/>

## Schema

#####  List schemas
```sql
\dn

\dn+

SELECT schema_name FROM information_schema.schemata;

SELECT nspname FROM pg_catalog.pg_namespace;
```

#####  Create a schema
http://www.postgresql.org/docs/current/static/sql-createschema.html
```sql
CREATE SCHEMA IF NOT EXISTS <schema_name>;
```

#####  Drop a schema
http://www.postgresql.org/docs/current/static/sql-dropschema.html
```sql
DROP SCHEMA IF EXISTS <schema_name> CASCADE;
```
<br/>

## Tables

##### List all tables, in current db (limited by your search_path)
```sql
\dt
\dt+

SELECT table_schema,table_name FROM information_schema.tables ORDER BY table_schema,table_name;
```

##### List tables, globally (not limited by search_path)
```sql
\dt *.*

SELECT * FROM pg_catalog.pg_tables
```

##### List table schema
```sql
\d <table_name>
\d+ <table_name>

SELECT column_name, data_type, character_maximum_length
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_name = '<table_name>';
```

<br/>

## Columns

##### Add a column
```sql
ALTER TABLE <table_name> IF EXISTS
ADD <column_name> <data_type> [<constraints>];
```

##### Change a column datatype
```sql
ALTER TABLE <table_name> IF EXISTS
ALTER <column_name> TYPE <data_type> [<constraints>];
```

##### Delete a column (beware of table locks)
```sql
ALTER TABLE <table_name> IF EXISTS
DROP <column_name>;
```
<br/>

## Scripting

##### Export table into CSV file
http://www.postgresql.org/docs/current/static/sql-copy.html
```sql
\copy <table_name> TO '<file_path>' CSV
```

##### Export table, only specific columns, to CSV file
```sql
\copy <table_name>(<column_1>,<column_1>,<column_1>) TO '<file_path>' CSV
```

##### Import CSV file into table
http://www.postgresql.org/docs/current/static/sql-copy.html
```sql
\copy <table_name> FROM '<file_path>' CSV
```

##### Import CSV file into table, only specific columns
```sql
\copy <table_name>(<column_1>,<column_1>,<column_1>) FROM '<file_path>' CSV
```
<br/>



