# Tutorial

## Database Preparation

This practical exercise involves the following steps:

1. **Obtain Tutorial SQL Files**  
   Download the required SQL files from the repository's [sql][] directory. This directory contains several `.sql` files and a `tutorial.zip` archive, which includes the same SQL files. Note that these files were created from the SQL code embedded in the repository's documentation.

2. **Create a New Database**  
   Start by creating a new blank SQLite database.

3. **Import the Schema Module**  
   Import the schema module `core_schema.sql` into the database.
   
4. **Import the Dummy Data Module**  
   Import the dummy data module `core_schema_dummy_data.sql`.
   
5. **Import Operation Modules**  
   Import the following modules in any order: `op_select.sql`, `op_create.sql`, `op_modify.sql`, `op_delete.sql`, and `op_export.sql`.  
   The remaining files - `dummy_select.sql`, `dummy_create.sql`, `dummy_modify.sql`, `dummy_delete.sql`, and `dummy_export.sql` - contain demo data corresponding to the "Dummy Data" sections of their respective documentation pages.  
   After completing this step, the database should contain:   
       - **4 non-system tables**  
       - **2 indexes**  
       - **24 views**  
       - **22 triggers**  
   Note: Most views will initially be empty, except for `exp_*` views, `ls_cat_empty`, and `ls_item_unfiled`.

6. **Import `dummy_select.sql`**  
   After importing this module, all `ls_*` and `cnt_*` views should display appropriate data. Additionally, the `hierarchy_ops.payload` field for `ls_*` operations should contain JSON-packed data.
   
7. **Import `dummy_export.sql`**  
   Importing this module updates the `exp_cat` view and populates the corresponding row in the `hierarchy_ops.payload` field.
   
8. **Import `dummy_create.sql`**  
   This module adds three rows to the `hierarchy_ops` table with the `payload` field set to `NULL`. However, the associated `new_*` views will not return any rows unless the associated `new_*` triggers are deleted before importing the module.
   
9. **Import `dummy_modify.sql` and `dummy_delete.sql`**  
   These modules add several rows to the `hierarchy_ops` table with the `payload` field set to `NULL`. The associated views will not provide useful information, so you should examine the affected data tables directly.

## Debugging and Troubleshooting SQL

SQLite is a compact, embeddable database engine—its entire functionality resides within a single library file, typically just a few megabytes in size. While this design offers portability and simplicity, it introduces unique considerations for debugging and troubleshooting, especially for users accustomed to full-scale client/server databases.

### Understanding SQLite's Compact Design

1. **Local Library Copies**:  
   Applications often ship with their own copy of the SQLite library. This flexibility is a core feature of SQLite but can lead to confusion:    
    - Different applications may use different versions of the SQLite library.
    - Without realizing this, you might inadvertently run code on several versions of SQLite, leading to inconsistent behavior or errors.
2. **Backward Compatibility vs. Recent Features**:  
    SQLite is renowned for its long-term backward compatibility. However:
    - Using newer features can cause issues if an application relies on an older SQLite version.
    - Relying on default assumptions about library versions can lead to sporadic, difficult-to-diagnose issues.
3. **Custom Builds and Features**:  
    SQLite's flexible build system allows developers to exclude unused features to save space.
    - A library's version number alone does not guarantee feature availability.
    - Features like JSON functions or advanced virtual table modules might be absent in some custom builds.

### Best Practices for Debugging and Troubleshooting

To avoid confusion and ensure consistent behavior, it is essential to determine:
- Which SQLite library copy is being used by each application.
- Which features are available in the current library build.

### Using Introspection Queries

The most reliable way to gather information about the SQLite engine in use is through introspection queries. For example, the following query returns key engine-related metadata:

```sql
WITH
    functions       AS (SELECT * FROM pragma_function_list()),
    collations      AS (SELECT * FROM pragma_collation_list()),
    compile_options AS (SELECT compile_options AS name
                        FROM pragma_compile_options()),
    modules         AS (SELECT * FROM pragma_module_list()),
    pragmas         AS (SELECT * FROM pragma_pragma_list()),
    engine_meta     AS (SELECT json_object(
        'version',                 sqlite_version(),
        'source_id',               sqlite_source_id(),
        'functions_count',         (SELECT count(name) FROM (
                                    SELECT name FROM functions GROUP BY name)),
        'functions',               (SELECT
                                        json_group_array(json_object(
                                            'name', name, 'builtin', builtin, 'type', type,
                                            'enc', enc, 'narg', narg, 'flags', flags
                                        ) ORDER BY name, narg)
                                FROM functions),
        'collations_count',        (SELECT count(name) FROM collations),
        'collations',              (SELECT json_group_array(name ORDER BY seq) FROM collations),
        'modules_count',           (SELECT count(name) FROM modules),
        'modules',                 (SELECT json_group_array(name ORDER BY name) FROM modules),
        'pragmas_count',           (SELECT count(name) FROM pragmas),
        'pragmas',                 (SELECT json_group_array(name ORDER BY name) FROM pragmas),
        'compile_options_count',   (SELECT count(name) FROM compile_options),
        'compile_options',         (SELECT json_group_array(name ORDER BY name) FROM compile_options)
    ) AS payload)
SELECT * FROM engine_meta;
```

Here’s how you might expand on SQLite's facilities for retrieving database-related metadata:

```sql
WITH
    tables          AS (SELECT name FROM sqlite_master WHERE type = 'table'
                                                         AND name NOT LIKE 'sqlite_%'),
    views           AS (SELECT name FROM sqlite_master WHERE type = 'view'),
    triggers        AS (SELECT name FROM sqlite_master WHERE type = 'trigger'),
    indexes         AS (SELECT name FROM sqlite_master WHERE type = 'index'
                                                         AND name NOT LIKE 'sqlite_%'),
    database_meta   AS (SELECT json_object(
        'application_id',         (SELECT * FROM pragma_application_id()),
        'user_version',           (SELECT * FROM pragma_user_version()),
        'schema_version',         (SELECT * FROM pragma_schema_version()),
        'journal_mode',           (SELECT * FROM pragma_journal_mode()),
        'databases',              (SELECT json_group_array(json_object('name', name, 'file', file) ORDER BY seq)
                                   FROM pragma_database_list()),
        'tables_count',           (SELECT count(name) FROM tables),
        'tables',                 (SELECT json_group_array(name ORDER BY name) FROM tables),
        'views_count',            (SELECT count(name) FROM views),
        'views',                  (SELECT json_group_array(name ORDER BY name) FROM views),
        'triggers_count',         (SELECT count(name) FROM triggers),
        'triggers',               (SELECT json_group_array(name ORDER BY name) FROM triggers),
        'indexes_count',          (SELECT count(name) FROM indexes),
        'indexes',                (SELECT json_group_array(name ORDER BY name) FROM indexes)
    ) AS payload)
SELECT * FROM database_meta;
```

### Validating Views and Triggers in SQLite

This project heavily relies on views and triggers, which introduces specific challenges in debugging and validation. SQLite allows creating views and triggers without validating all identifiers used within them at the time of creation. This means a view or trigger might include invalid column references or other errors, and the `CREATE` statement will still succeed. However, these errors will surface later when attempting to execute queries involving the faulty objects.

#### Challenges with Views and Triggers

1. **Deferred Error Detection**:  
   Errors in views and triggers are detected only when the problematic object is invoked, making it harder to pinpoint the source of the issue.
2. **Unhelpful Error Messages**:  
   SQLite error messages in such cases might not clearly indicate the specific cause or location of the issue, complicating debugging.

#### Validating Views

To validate views for plain errors, the simplest method is to execute a basic query for each view. For example:
```sql
SELECT * FROM view_name LIMIT 1;
```
This ensures that the view is syntactically correct and all referenced identifiers are valid.

##### Automating Validation

Manually testing each view can be tedious in databases with many views. To simplify this process, you can generate a set of `SELECT` statements dynamically for all views in the database:

```sql
SELECT 'SELECT * FROM "' || name || '" LIMIT 1;' AS validation_query
FROM sqlite_schema
WHERE type = 'view';
```

**Explanation**:
- The query extracts the names of all views in the database from `sqlite_schema`.
- For each view, it generates a corresponding `SELECT` statement to validate the view's structure.

Note, when testing views, consider temporarily dropping all triggers to prevent side effects or misleading error messages.  

#### Validating Triggers

Triggers are harder to validate automatically, as their code depends on specific events or operations (e.g., `INSERT`, `UPDATE`, or `DELETE`). Unlike views, they are not directly invoked through SQL queries. To mitigate potential issues, test tables may be created to trigger the events and confirm expected behavior. Then, triggers are created on the test tables one at a time, and the action is triggered. To ensure that the trigger was activated, its code may be appended with an `INSERT` statement that uses a temporary "log" table. For the database, used in this tutorial, I have come up with the following code:

```sql
SELECT
   'DROP TABLE IF EXISTS "temp"."hierarchy_ops";
    CREATE TEMP TABLE "hierarchy_ops" (
        "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
        "op_name"   TEXT    NOT NULL COLLATE NOCASE,
        "json_op"   TEXT    COLLATE NOCASE,
        "payload"   TEXT
    );' || x'0A0A' ||
    group_concat(concat_ws(x'0A0A',
        'DROP TRIGGER IF EXISTS temp."' || name || '";',
        replace(
            replace(sql, ' "' || tbl_name || '"', ' temp."' || tbl_name || '"'),
            ' "' || name || '"',
            ' temp."' || name || '"'
        ) || ';',
        'INSERT INTO temp."' || tbl_name || '"(op_name) VALUES (''dummy''); -- TRIGGER: ' || name,
        'DROP TRIGGER IF EXISTS temp."' || name || '";'
    ), x'0A0A') || x'0A0A' ||
    'DROP TABLE IF EXISTS "temp"."hierarchy_ops";' AS sql
FROM main.sqlite_master
WHERE type = 'trigger';
```

The provided SQL code generates a single SQL script that can be used to test and debug triggers defined in the current SQLite database. Below is an explanation of how the query works, broken down step by step:

##### Overview

The goal of this script is to:
1. Create a temporary table (`hierarchy_ops`): Acts as a dummy table for testing triggers.
2. Duplicate triggers: Temporarily recreate triggers to operate on the temporary table instead of their original table.
3. Test trigger execution: Insert dummy data into the temporary table to activate the recreated triggers.
4. Clean up: Drop all the recreated triggers and the temporary table after testing.

##### Code Breakdown
###### 1. Create the Temporary Table
```sql
'DROP TABLE IF EXISTS "temp"."hierarchy_ops";
 CREATE TEMP TABLE "hierarchy_ops" (
     "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
     "op_name"   TEXT    NOT NULL COLLATE NOCASE,
     "json_op"   TEXT    COLLATE NOCASE,
     "payload"   TEXT
 );' || x'0A0A' ||
```
- Purpose: The script begins by creating a temporary table (`temp.hierarchy_ops`) in the `temp` schema. This table mimics a table on which triggers might operate.
- `DROP TABLE IF EXISTS`: Ensures the temporary table is removed if it already exists, avoiding conflicts.
- Temporary Table (`TEMP TABLE`): Exists only for the duration of the database connection and is isolated from the permanent database.

###### 2. Iterate Over Triggers
```sql
group_concat(concat_ws(x'0A0A',
    'DROP TRIGGER IF EXISTS temp."' || name || '";',
    replace(
        replace(sql, ' "' || tbl_name || '"', ' temp."' || tbl_name || '"'),
        ' "' || name || '"',
        ' temp."' || name || '"'
    ) || ';',
    'INSERT INTO temp."' || tbl_name || '"(op_name) VALUES (''dummy''); -- TRIGGER: ' || name,
    'DROP TRIGGER IF EXISTS temp."' || name || '";'
), x'0A0A')
```
- Purpose: Processes all triggers in the database, modifying and testing them against the temporary table.
- `group_concat`: Combines multiple SQL statements into one script, separated by the binary newline character (`x'0A0A'`).
- `concat_ws`: Combines:
  1. Drop the trigger if it exists: Ensures the trigger is recreated cleanly.
```sql
     'DROP TRIGGER IF EXISTS temp."' || name || '";'
```

  2. Modify the trigger SQL: Replaces references to the original table and trigger with references to the temporary table and recreated trigger.

```sql
     replace(
         replace(sql, ' "' || tbl_name || '"', ' temp."' || tbl_name || '"'),
         ' "' || name || '"',
         ' temp."' || name || '"'
     ) || ';'
```
     - `tbl_name`: The table on which the trigger operates.
     - Replacements: Adjust references to tables and triggers to point to the `temp` schema.
  3. Test the trigger: Inserts dummy data into the temporary table, which will activate the recreated trigger.

```sql
     'INSERT INTO temp."' || tbl_name || '"(op_name) VALUES (''dummy''); -- TRIGGER: ' || name
```
  
  4. Clean up the recreated trigger: Drops the temporary trigger after testing.
  
```sql
     'DROP TRIGGER IF EXISTS temp."' || name || '";'
```

###### 3. Clean Up the Temporary Table

```sql
|| x'0A0A' || 'DROP TABLE IF EXISTS "temp"."hierarchy_ops";' AS sql
```

- Purpose: Ensures the temporary table (`temp.hierarchy_ops`) is dropped at the end of the script to avoid leaving any residual data or schema.

###### 4. Filter for Triggers

```sql
FROM main.sqlite_master
WHERE type = 'trigger';
```

- Purpose: Filters the `sqlite_master` table for objects of type `trigger` in the `main` schema. This ensures that only triggers are processed.

---

##### How It Works

1. Initial Setup: A temporary table (`temp.hierarchy_ops`) is created.
2. Trigger Processing:
   - For each trigger in the database:
     1. A temporary version of the trigger is created, adjusted to operate on the temporary table.
     2. Dummy data is inserted into the temporary table to activate the trigger.
     3. The temporary trigger is dropped after execution.
3. Final Cleanup: The temporary table is dropped after all triggers have been tested.

---

##### Purpose

- Debugging Triggers: The script allows you to test triggers without modifying the original tables or schema.
- Error Isolation: By isolating the triggers in a temporary schema, it becomes easier to identify and debug issues.
- Automation: The use of dynamic SQL (`group_concat`, `replace`) ensures that the process adapts automatically to the triggers defined in the database.

---

| [**<= EXPORT Operations**][EXPORT] |
| ---------------------------------- |

<!-- References -->

[EXPORT]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopEXPORT.md
[sql]: https://github.com/pchemguy/SQLiteMP/tree/main/sqlitemp/src/sqlitemp/sql
