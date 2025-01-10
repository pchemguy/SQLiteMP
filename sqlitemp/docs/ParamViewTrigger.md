# Pseudo-Parameterized Views and Triggers

While the standard SQLite library does not natively support stored procedures, complex SQL logic can be embedded within a database's views and triggers. Unlike stored procedures, which can typically accept query parameters as arguments, views and triggers lack this capability. A potential workaround for this limitation involves using an auxiliary buffer table. For example, consider the following schema:

```sql
DROP TABLE IF EXISTS "environment";
CREATE TABLE "environment" (
    "name"     TEXT PRIMARY KEY NOT NULL COLLATE NOCASE,
    "value"    TEXT COLLATE NOCASE
);

DROP VIEW IF EXISTS "ascii_id_generator";
CREATE VIEW "ascii_id_generator" AS
WITH
    id_counts(id_counter) AS (SELECT value FROM environment WHERE name = 'ID_COUNTER'),
    json_templates AS (
        SELECT '[' || replace(hex(zeroblob(id_counter*8/2-1)), '0', '0,') || '0,0]' AS json_template
        FROM id_counts
    ),
    char_templates(char_template) AS (
        VALUES ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzAa')
    ),
    ascii_ids AS (
        SELECT group_concat(substr(char_template, (random() & 63) + 1, 1), '') AS ascii_id, "key"/8 + 1 AS counter
        FROM char_templates, json_templates, json_each(json_templates.json_template) AS terms
        GROUP BY counter
    ),
    ids AS (
        SELECT counter, ascii_id,
               (unicode(substr(ascii_id, 1, 1)) << 8*7) +
               (unicode(substr(ascii_id, 2, 1)) << 8*6) +
               (unicode(substr(ascii_id, 3, 1)) << 8*5) +
               (unicode(substr(ascii_id, 4, 1)) << 8*4) +
               (unicode(substr(ascii_id, 5, 1)) << 8*3) +
               (unicode(substr(ascii_id, 6, 1)) << 8*2) +
               (unicode(substr(ascii_id, 7, 1)) << 8*1) +
               (unicode(substr(ascii_id, 8, 1)) << 8*0) AS bin_id
        FROM ascii_ids
    )
SELECT * FROM ids;
```

The `environment` table mimics the functionality of environment variables. The `ascii_id_generator` view code is adapted from a [previously published snippet][ASCII ID generator] with minor modifications. The number of rows returned by the view is determined by the value of the `environment.value` field where `name` = "ID_COUNTER". By updating this field - for instance, through a basic parameterized `INSERT OR REPLACE` query - you can effectively pass a parameter to the `ascii_id_generator` view, which will then generate and return the specified number of new IDs. This approach can be seamlessly extended to work with triggers as well.

---  

| [**<= Previous: Storing Code in an SQLite Database**][StoredCode] | [**Next: SELECT Operations =>**][SELECT] |
| ----------------------------------------------------------------- | ---------------------------------------- |

<!-- References -->

[ASCII ID generator]: https://pchemguy.github.io/SQLite-SQL-Tutorial/patterns/ascii-id
[StoredCode]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/StoredCode.md
[SELECT]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopSELECT.md