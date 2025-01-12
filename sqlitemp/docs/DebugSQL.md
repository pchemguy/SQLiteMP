## Engine Metadata

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

## Database Metadata

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

## Testing Views

```sql
SELECT group_concat('SELECT * FROM ' || name || ';', x'0A') AS view_test
FROM sqlite_master
WHERE type = 'view';
```

## Testing Triggers

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
    ), x'0A0A') AS sql
FROM main.sqlite_master
WHERE type = 'trigger';
```