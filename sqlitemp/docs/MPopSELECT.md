# SELECT Operations

## Summary

Each hierarchy operation may have an associated a view and trigger.

| <center>Group</center> | <center>Operation</center>     | <center>`op_name`</center> | <center>Description</center>                                                            |
| ---------------------- | ------------------------------ | -------------------------- | --------------------------------------------------------------------------------------- |
| SELECT                 | Descendant categories          | `ls_cat_desc`              | Given a set of categories, retrieve the set of descendant categories.                   |
| SELECT                 | Child categories               | `ls_cat_child`             | Given a set of categories, retrieve the set of child categories.                        |
| SELECT                 | Descendant items               | `ls_item_desc`             | Given a set of categories, retrieve the set of items associated with subtrees.          |
| SELECT                 | Child items                    | `ls_item_child`            | Given a set of categories, retrieve the set of directly associated items.               |
| SELECT                 | Item associations              | `ls_item_cat`              | Given an item, retrieve the set of associated categories.                               |
| SELECT                 | Item association counts        | `cnt_item_cat`             | Given a set of items, retrieve the number of categories associated with each item.      |
| SELECT                 | Child items association counts | `cnt_item_child_cat`       | Given a category, retrieve *item association counts* for all directly associated items. |

---
---

## Descendant Categories - `ls_cat_desc`

Given a set of categories, retrieve the set of descendant categories.

### View

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

Note the use of an additional path separator to ensure accurate matches:

```sql
WHERE path_old || '/' LIKE rootpath_old || '/%'
```

For example, consider the following list of categories:

```json
[
    "/food/cheese",
    "/food/cheese/blue",
    "/food/cheeseburger"
]
```

Without the extra path separator, `path_old` = `/food/cheese` would incorrectly match all three categories. Adding the separator ensures that only the first two categories are matched as intended.

### Trigger

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
        FROM ls_cat_desc
    )
	WHERE id = NEW.id;
END;
```

### Dummy data

```sql
-- Data for retrieving descendant categories
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

## Child Categories - `ls_cat_child`

Given a set of categories, retrieve the set of child categories.

### View

```sql
-- Retrieves child categories
DROP VIEW IF EXISTS "ls_cat_child";
CREATE VIEW "ls_cat_child" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'ls_cat_child'
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
        WHERE categories.parent_path = base_ops.path
    )
SELECT * FROM nodes
ORDER BY path;
```

### Trigger

```sql
-- Retrieves child categories
DROP TRIGGER IF EXISTS "ls_cat_child";
CREATE TRIGGER "ls_cat_child"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_cat_child'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY path) AS json_data
        FROM ls_cat_child
    )
	WHERE id = NEW.id;
END;
```

### Dummy data

```sql
-- Data for retrieving child categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_cat_child', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Descendant Items - `ls_item_desc`

Given a set of categories, retrieve the set of items associated with subtrees.

### View

```sql
-- Retrieves descendant items
DROP VIEW IF EXISTS "ls_item_desc";
CREATE VIEW "ls_item_desc" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'ls_item_desc'
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
        SELECT items.*
        FROM categories, items, items_categories, base_ops
        WHERE categories.path || '/' LIKE base_ops.path || '/%'
		  AND categories.path = items_categories.cat_path
		  AND items.handle = items_categories.item_handle
    )
SELECT * FROM nodes
ORDER BY name;
```

### Trigger

```sql
-- Retrieves descendant items
DROP TRIGGER IF EXISTS "ls_item_desc";
CREATE TRIGGER "ls_item_desc"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_item_desc'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY name) AS json_data
        FROM ls_item_desc
    )
	WHERE id = NEW.id;
END;
```

### Dummy data

```sql
-- Data for retrieving descendant items
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_item_desc', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Child Items - `ls_item_desc`

Given a set of categories, retrieve the set of directly associated items.

### View

```sql
-- Retrieves child items
DROP VIEW IF EXISTS "ls_item_child";
CREATE VIEW "ls_item_child" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'ls_item_child'
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
        SELECT items.*
        FROM categories, items, items_categories, base_ops
        WHERE categories.path = base_ops.path
		  AND categories.path = items_categories.cat_path
		  AND items.handle = items_categories.item_handle
    )
SELECT * FROM nodes
ORDER BY name;
```

### Trigger

```sql
-- Retrieves child items
DROP TRIGGER IF EXISTS "ls_item_child";
CREATE TRIGGER "ls_item_child"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_item_child'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY name) AS json_data
        FROM ls_item_child
    )
	WHERE id = NEW.id;
END;
```

### Dummy data

```sql
-- Data for retrieving child items
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_item_child', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Item Associations - `ls_item_cat`

Given an item, retrieve the set of associated categories.

### View

```sql
-- Retrieves item associations
DROP VIEW IF EXISTS "ls_item_cat";
CREATE VIEW "ls_item_cat" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'ls_item_cat'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            value AS item_handle
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    nodes AS (
        SELECT categories.*
        FROM categories, items, items_categories, base_ops
        WHERE items.handle = base_ops.item_handle
		  AND items.handle = items_categories.item_handle
		  AND categories.path = items_categories.cat_path
    )
SELECT * FROM nodes
ORDER BY path;
```

### Trigger

```sql
-- Retrieves item associations
DROP TRIGGER IF EXISTS "ls_item_cat";
CREATE TRIGGER "ls_item_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_item_cat'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY path) AS json_data
        FROM ls_item_cat
    )
	WHERE id = NEW.id;
END;
```

### Dummy data

```sql
-- Data for retrieving item associations
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_item_cat', json('[' || concat_ws(',',
                '"0764037c54441d43fc57d370dfe203e6"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Item Association Counts - `cnt_item_cat`

Given a set of items, retrieve the number of categories associated with each item

### View

```sql
-- Retrieves item association counts
DROP VIEW IF EXISTS "cnt_item_cat";
CREATE VIEW "cnt_item_cat" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'cnt_item_cat'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            value AS item_handle
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    nodes AS (
        SELECT items.*, count(items_categories.cat_path) AS cat_cnt
        FROM items, items_categories, base_ops
        WHERE items_categories.item_handle = base_ops.item_handle
		  AND items.handle = items_categories.item_handle
		GROUP BY items_categories.item_handle
    )
SELECT * FROM nodes
ORDER BY name;
```


### Dummy data

```sql
-- Data for retrieving item association counts
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('cnt_item_cat', json('[' || concat_ws(',',
                '"007ebc73169d3cfd9c72ff3cefdfae560"',
                '"08f17f6155577f349cb26709ffc8c189"',
                '"0932de56b45b0d77f39fac31427491f4"',
                '"09ec2bbbb61735163017bee90e46aaed1"',
                '"0764037c54441d43fc57d370dfe203e6"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Child Items  Association Counts - `cnt_item_child_cat`

Given a category, retrieve *item association counts* for all directly associated items.

### View

```sql
-- Retrieves child items association counts
DROP VIEW IF EXISTS "cnt_item_child_cat";
CREATE VIEW "cnt_item_child_cat" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'cnt_item_child_cat'
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
        SELECT items.*,  count(cnts.cat_path) AS cat_cnt
        FROM items, items_categories, items_categories AS cnts, base_ops
        WHERE items_categories.cat_path = base_ops.path
		  AND items.handle = items_categories.item_handle
		  AND items.handle = cnts.item_handle
		GROUP BY cnts.item_handle
    )
SELECT * FROM nodes
ORDER BY name;
```

### Dummy data

```sql
-- Data for retrieving child items association counts
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('cnt_item_child_cat', json('[' || concat_ws(',',
				'"/Project/SQLite/MetaSQL/Examples"',
                '"/Assets/Diagrams"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

---

| [**<= Previous: Pseudo-Parameterized Views and Triggers**][ParamViewTrigger] | [**Next:  CREATE Operations=>**][CREATE] |
| ---------------------------------------------------------------------------- | ---------------------------------------- |


<!-- References -->

[ParamViewTrigger]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/ParamViewTrigger.md
[CREATE]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopCREATE.md