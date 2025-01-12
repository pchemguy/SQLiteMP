## SQLite Engine Metadata

```sql
WITH
    functions       AS (SELECT * FROM pragma_function_list()),
    collations      AS (SELECT * FROM pragma_collation_list()),
    compile_options AS (SELECT compile_options AS name
                        FROM pragma_compile_options()),
    modules         AS (SELECT * FROM pragma_module_list()),
    pragmas         AS (SELECT * FROM pragma_pragma_list()),
    engine_meta     AS (SELECT json_object(
         'version',                sqlite_version(),
         'source_id',              sqlite_source_id(),
         'functions_count',        (SELECT count(name) FROM (
                                        SELECT name FROM functions GROUP BY name)),
         'functions',              (SELECT
                                        json_group_array(json_object(
                                            'name', name, 'builtin', builtin, 'type', type,
                                            'enc', enc, 'narg', narg, 'flags', flags
                                        ) ORDER BY name, narg)
                                    FROM functions),
         'collations_count',       (SELECT count(name) FROM collations),
         'collations',             (SELECT json_group_array(name ORDER BY seq) FROM collations),
         'modules_count',          (SELECT count(name) FROM modules),
         'modules',                (SELECT json_group_array(name ORDER BY name) FROM modules),
         'pragmas_count',          (SELECT count(name) FROM pragmas),
         'pragmas',                (SELECT json_group_array(name ORDER BY name) FROM pragmas),
         'compile_options_count',  (SELECT count(name) FROM compile_options),
         'compile_options',        (SELECT json_group_array(name ORDER BY name) FROM compile_options)
    ) AS payload)
SELECT * FROM engine_meta;
```
