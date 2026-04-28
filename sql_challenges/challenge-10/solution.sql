-- Lesson 05: Schema Backup & Restore
-- solution.sql

-- EXERCISE 1: Explore your schema
-- Instruction: List the objects in the current schema and count them by type.

SELECT object_type, COUNT(*) AS total_objects
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

SELECT object_name, object_type, created, last_ddl_time
FROM user_objects
ORDER BY object_type, object_name;


-- EXERCISE 2: Basic GET_DDL
-- Instruction: Configure DBMS_METADATA and extract the DDL of the schema tables.

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

SET LONG 100000
SET PAGESIZE 0

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) AS table_ddl
FROM user_tables
ORDER BY table_name;


-- EXERCISE 3: Clean DDL for portability
-- Instruction: Generate clean DDL without schema names so it can be used in another schema.

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) AS portable_table_ddl
FROM user_tables
ORDER BY table_name;


-- EXERCISE 4: Plan a migration
-- Instruction: Review schema references and foreign keys before moving to a new schema.

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) AS migration_table_ddl
FROM user_tables
ORDER BY table_name;

SELECT constraint_name, table_name, r_constraint_name
FROM user_constraints
WHERE constraint_type = 'R'
ORDER BY table_name, constraint_name;

-- Answer:
-- To migrate from SCHEMA_OLD to SCHEMA_NEW, I would first export the DDL with EMIT_SCHEMA = FALSE.
-- This avoids hardcoding the old schema name in the generated SQL.
-- Then I would review all foreign keys, constraints, indexes, views, sequences, and PL/SQL objects.
-- If any object still references SCHEMA_OLD, I would replace it with SCHEMA_NEW or remove the schema prefix if the referenced object exists in the same schema.
-- After cleaning the DDL, I would recreate the objects in the correct order: tables, sequences, indexes, constraints, views, procedures, functions, packages, and triggers.


-- EXERCISE 5: Dependency order
-- Instruction: Check dependencies to understand which objects must be created first during restore.

SELECT referenced_name, referencing_name, referencing_type
FROM user_dependencies
ORDER BY referenced_name, referencing_name;

SELECT referencing_name, referencing_type
FROM user_dependencies
WHERE referenced_name IN (
  SELECT table_name
  FROM user_tables
)
ORDER BY referencing_type, referencing_name;

SELECT referencing_name,
       referencing_type,
       LISTAGG(referenced_name, ', ') WITHIN GROUP (ORDER BY referenced_name) AS dependencies
FROM user_dependencies
WHERE referencing_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION')
GROUP BY referencing_name, referencing_type
ORDER BY referencing_type, referencing_name;

-- Answer:
-- Tables should usually be created first because many objects depend on them.
-- After tables, I would create sequences and indexes.
-- Then I would add constraints, especially foreign keys, because they may depend on other tables.
-- Views and PL/SQL code should be created later because they can depend on tables, views, or other code objects.


-- EXERCISE 6: Design your own backup strategy
-- Instruction: Design a backup and restore strategy using only SQL access.

SELECT object_type, COUNT(*) AS total_objects
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

SELECT table_name, num_rows
FROM user_tables
ORDER BY num_rows DESC NULLS LAST;

BEGIN
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'EMIT_SCHEMA', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'PRETTY', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SQLTERMINATOR', TRUE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'SEGMENT_ATTRIBUTES', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'STORAGE', FALSE);
  DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM, 'TABLESPACE', FALSE);
END;
/

SELECT DBMS_METADATA.GET_DDL('TABLE', table_name) AS table_ddl
FROM user_tables
ORDER BY table_name;

SELECT DBMS_METADATA.GET_DDL('SEQUENCE', sequence_name) AS sequence_ddl
FROM user_sequences
ORDER BY sequence_name;

SELECT DBMS_METADATA.GET_DDL('INDEX', index_name) AS index_ddl
FROM user_indexes
ORDER BY index_name;

SELECT DBMS_METADATA.GET_DDL('CONSTRAINT', constraint_name) AS constraint_ddl
FROM user_constraints
WHERE constraint_type IN ('P', 'U', 'R', 'C')
ORDER BY table_name, constraint_name;

SELECT DBMS_METADATA.GET_DDL('VIEW', view_name) AS view_ddl
FROM user_views
ORDER BY view_name;

SELECT DBMS_METADATA.GET_DDL('PROCEDURE', object_name) AS procedure_ddl
FROM user_objects
WHERE object_type = 'PROCEDURE'
ORDER BY object_name;

SELECT DBMS_METADATA.GET_DDL('FUNCTION', object_name) AS function_ddl
FROM user_objects
WHERE object_type = 'FUNCTION'
ORDER BY object_name;

SELECT DBMS_METADATA.GET_DDL('PACKAGE', object_name) AS package_ddl
FROM user_objects
WHERE object_type = 'PACKAGE'
ORDER BY object_name;

SELECT DBMS_METADATA.GET_DDL('TRIGGER', object_name) AS trigger_ddl
FROM user_objects
WHERE object_type = 'TRIGGER'
ORDER BY object_name;

SELECT object_type, COUNT(*) AS total_objects
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

SELECT table_name, num_rows
FROM user_tables
ORDER BY table_name;

SELECT index_name, table_name
FROM user_indexes
ORDER BY index_name;

-- Answer:
-- My backup strategy would start by documenting the current schema with user_objects and user_tables.
-- Then I would configure DBMS_METADATA to generate clean and portable DDL.
-- I would export the DDL for tables, sequences, indexes, constraints, views, procedures, functions, packages, and triggers.
-- Since I only have SQL access, I would copy or spool the generated output into a SQL file.
-- For the restore, I would run the scripts in order: tables, sequences, indexes, constraints, views, PL/SQL code, and triggers.
-- Finally, I would verify the restore by comparing object counts, table names, indexes, and sample queries.


-- DISCUSSION QUESTIONS

-- Q1: What are the limitations of DBMS_METADATA vs expdp?
-- Answer:
-- DBMS_METADATA is useful because it lets us extract the DDL of database objects using SQL.
-- However, it mainly exports structure, not the actual data.
-- It also requires more manual work because we need to copy or spool the output and organize the restore order.
-- expdp is more complete because it can export both data and structure, and it works better for large schemas.
-- The disadvantage is that expdp usually requires more privileges, such as directory access.

-- Q2: If you have circular dependencies, how would you handle the reload?
-- Answer:
-- I would create the main objects first without depending too much on the order of constraints.
-- For tables with circular foreign keys, I would create the tables first and add the foreign key constraints later.
-- For PL/SQL objects, I would create package specifications first and package bodies after that.
-- This helps avoid errors during restore because the required objects already exist before enabling dependencies.

-- Q3: Your company is migrating from one Oracle database to another. They give you read-only access to the old database and want you to recreate the schema on the new database. What's your plan?
-- Answer:
-- First, I would document the source schema by checking user_objects, user_tables, user_constraints, user_indexes, user_views, and user_dependencies.
-- Then I would use DBMS_METADATA to generate clean DDL with EMIT_SCHEMA = FALSE.
-- After that, I would review the generated SQL to remove old schema references, storage settings, or anything that does not apply to the new database.
-- Then I would run the restore in the correct order: tables, sequences, indexes, constraints, views, procedures, functions, packages, and triggers.
-- Finally, I would verify the migration by comparing the number of objects and running sample queries to make sure the schema works correctly.
