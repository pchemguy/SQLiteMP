# High Level API

## Retrieve Descendant Categories

Let's start with a basic example

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
    nodes AS(
        SELECT categories.*
        FROM categories, base_ops
        WHERE categories.path || '/' LIKE base_ops.path || '/%'
    )
SELECT id, name, parent_path, ascii_id, path FROM nodes
ORDER BY path;
```

The code above retrieves the list of descendant categories for a given set of nodes. The first CTE `json_ops` defines a table:

| op_name     | json_op |
| ----------- | ------- |
| ls_cat_desc | {data}  |


---

| [**<= Materialized path operations**][MPops] | [**Next: High Level API =>**][MPops] |
| -------------------------------------------- | ------------------------------------ |


<!-- References -->

[MPops]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPops.md