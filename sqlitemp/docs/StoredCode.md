# Storing Code in an SQLite Database

To demonstrate the key ideas, let's start with a basic example that retrieves the list of descendant categories for a given set of nodes:

## Base Query

```sql
-- Retrieves descendant categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_cat_desc', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            value AS path
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    nodes AS (
        SELECT categories.*
        FROM categories, base_ops
        WHERE categories.parent_path || '/' LIKE base_ops.path || '/%'
    )
SELECT * FROM nodes
ORDER BY path;
```

The first CTE `json_ops` defines a table:

| op_name     | json_op     |
| ----------- | ----------- |
| ls_cat_desc | `{payload}` |

where `{payload}` is a JSON array of target category paths:

```json
[
    "/Assets/Diagrams",
    "/Library/Drafts/DllTools/Dem - DLL/memtools",
    "/Project/SQLiteDBdev"
]
```

The second CTE `base_ops` unpacks the JSON object into a table:

| <center>opid</center> | <center>path</center>                       |
| :-------------------: | ------------------------------------------- |
|           1           | /Assets/Diagrams                            |
|           2           | /Library/Drafts/DllTools/Dem - DLL/memtools |
|           3           | /Project/SQLiteDBdev                        |

The last CTE `nodes` retrieves descendant categories from the `categories` table.

## Parameterized Query

The next logical step would be to convert the query above into a parameterized query for use in an application:

```sql
-- Retrieves descendant categories
WITH
    json_ops(op_name, json_op) AS (VALUES ('ls_cat_desc', ?)),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            value AS path
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    nodes AS (
        SELECT categories.*
        FROM categories, base_ops
        WHERE categories.parent_path || '/' LIKE base_ops.path || '/%'
    )
SELECT * FROM nodes
ORDER BY path;
```

but let us explore a different approach.

## Hierarchy Operations Table

Let's define another table:

| <center>Field</center> | <center>Attributes</center> | <center>Description</center>                            |
| ---------------------- | :-------------------------: | ------------------------------------------------------- |
| **`id`**               |    **INTEGER**<br>**PK**    |                                                         |
| **`op_name`**          |          **TEXT**           | Name of operation.                                      |
| **`json_op`**          |          **TEXT**           | JSON-formatted string containing operation information. |
| **`payload`**          |          **TEXT**           | JSON-packed response data (set by triggers).            |

```sql
DROP TABLE IF EXISTS "hierarchy_ops";
CREATE TABLE "hierarchy_ops" (
    "id"        INTEGER PRIMARY KEY AUTOINCREMENT,
    "op_name"   TEXT    NOT NULL COLLATE NOCASE,
    "json_op"   TEXT    NOT NULL COLLATE NOCASE,
    "payload"   TEXT
);
```

This table will be used to facilitate materialized path operations, such as:

```sql
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_cat_desc', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

The content of the `json_ops` CTE is identical to the data in the earlier query. The `op_name = 'ls_cat_desc'` value represents an arbitrarily defined operation name used to retrieve the list of descendant categories. Now, let’s define a view:

```sql
-- Retrieves descendant categories
DROP VIEW IF EXISTS "ls_cat_desc";
CREATE VIEW "ls_cat_desc" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'ls_cat_desc'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            value AS path
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    nodes AS (
        SELECT categories.*
        FROM categories, base_ops
        WHERE categories.parent_path || '/' LIKE base_ops.path || '/%'
    )
SELECT * FROM nodes
ORDER BY path;
```

This view incorporates a modified version of the earlier query. The first `json_ops` CTE retrieves the JSON input from the `hierarchy_ops` table by selecting the most recently inserted row with a matching `op_name` value. The rest of the code is identical to the previously shown query. To retrieve descendant categories, the application can now submit a command using the query:

```sql
INSERT INTO hierarchy_ops(op_name, json_op) VALUES ($op_name, $json_op);
```

And the result can be retrieved directly, for example:

```sql
SELECT * FROM ls_cat_desc;
```

Finally, let's us define a trigger:

```sql
-- Retrieves descendant categories
DROP TRIGGER IF EXISTS "ls_cat_desc";
CREATE TRIGGER "ls_cat_desc"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_cat_desc'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY path) AS json_data
        FROM dir_cats
    )
	WHERE id = NEW.id;
END;
```

The trigger code packs retrieved categories into a JSON string and sets the `payload` field of the record defining the operation. 

## Summary

By leveraging a strategy that combines JSON-based input and output with views and triggers, it is possible to store complex code directly in an SQLite database, thereby minimizing the application's responsibility for managing SQL code. One significant advantage of using triggers is their ability to encapsulate multiple DML queries, functioning as a limited equivalent of stored procedures. According to the official documentation, top-level trigger statements do not support the `WITH` clause (CTE), but CTEs can be included in subqueries, making this limitation relatively minor. Views, on the other hand, can store complex `SELECT` queries, which may be used to return data to the application or preprocess parameterized queries that serve as inputs for trigger routines.

Although queries stored as views or trigger code cannot be parameterized directly, parameterization can be implemented in a straightforward manner by using an auxiliary "buffer" table, as demonstrated above with the `hierarchy_ops` table. When views and triggers are properly configured, common database operations can often be reduced to just two queries:

```sql
INSERT INTO hierarchy_ops(op_name, json_op) VALUES ($op_name, $json_op);
SELECT payload FROM hierarchy_ops WHERE op_name = $op_name ORDER BY id DESC LIMIT 1
```

with JSON based input (`$json_op`) and output (`payload`).

An additional advantage of this approach is that it ensures associated triggers are executed only once per operation (similar to `FOR EACH STATEMENT` triggers), regardless of the number of rows inserted into the target tables.

---

| [**<= Materialized path operations**][MPops] | [**Next: SELECT Operations =>**][SELECT] |
| -------------------------------------------- | ---------------------------------------- |


<!-- References -->

[MPops]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPops.md
[SELECT]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopSELECT.md
