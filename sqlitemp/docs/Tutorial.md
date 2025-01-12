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

A few preliminary notes on debugging and troubleshooting SQL code with SQLite. First of all, it is important to keep in mind that SQLite is a compact and embeddable engine - the entire SQLite engine fits within a single local library file a few MB large. At least on Windows, applications are usually shipped with their own copy of the library. This is a feature of SQLite, when used appropriately. But when one approaches SQLite with experience and intuition based on full-size client/server databases, this feature may cause confusion and result in apparently sporadic difficult to pinpoint issues. When I started figuring out how to use SQLite from Excel/VBA, I also used a couple SQLite administration tools, and it took me some time to realize, that each application used its own copy of the library. SQLite is renown for its long backward compatibility, but when it comes to using recent features, running the code in the course of development on several different versions of the library without clear understanding of this matter might be problematic. Furthermore, SQLite also has a flexible build system that makes it possible to not include unused features in custom builds to save space. Because of this, unless the official release is used by all applications of interest (which is most likely not the case), the library version number is not sufficient to understand which features are available. For these reasons, it is important to understand which particular copy of the library is used at any given time and which features are available. The most straightforward and reliable way to obtain this information is by executing introspection SQL queries on the database connection of interest. For example, the following query returns most of the engine related metadata provided by SQLite:

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

SQLite also provides facilities to retrieve database related metadata, for example:

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

Because this project heavily relies on views and triggers, I wanted to talk about these object specifically. As it turns out, When a view or trigger is created, SQLite does not validate identifiers used. That means that a view or trigger code may include, for example, an invalid column reference, but the DDL statement would still succeed, but an error will be thrown later when attempting executing other queries. In such a case, tracing view/trigger bugs might be quite difficult, because the error messages may not be particularly helpful in such a situation.

Views can be validated (for plain errors) relatively straightforwardly. The idea is that we want to reference each view in SQL statements one per statement and make sure that such statements can be executed without errors, For this test, it may make sense to drop all triggers, although this precaution might be excessive. The most simple approach is probably to select all rows from the view. The only issue is that doing this test for multiple views manually might be tedious. To simplify this process, the following query generates a full set of `SELECT` statements:

```sql
SELECT group_concat('SELECT * FROM ' || name || ';', x'0A') AS view_test
FROM sqlite_master
WHERE type = 'view';
```

When its output is executed in a modern GUI dba tool, the first defective view, if present will cause failure of the associated statement, revealing the problematic view. If this test passes, the next step is to check triggers.

Triggers are trickier, however, because they cannot be executed directly. For the database, used in this tutorial, I have come up with the following code:

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

As before, the code generates SQL to be executed. The first generated query creates a twin of the `hierarchy_ops` table in the `temp` database. The rest of the code retrieves sql of all triggers, patches them with the `temp` database reference (in a fragile manner) and generates updated SQL for creating twin triggers in the `temp` database. After each trigger is created, an `INSERT` statement targeting the twin table is created. Only one trigger exists in the `temp` database at any given time. Thus, if any trigger is defective, the associated `INSERT` should fail, pointing out that view.

---

| [**<= EXPORT Operations**][EXPORT] |
| ---------------------------------- |

<!-- References -->

[EXPORT]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopEXPORT.md
[sql]: https://github.com/pchemguy/SQLiteMP/tree/main/sqlitemp/src/sqlitemp/sql
