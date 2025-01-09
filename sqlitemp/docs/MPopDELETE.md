# DELETE Operations

## Summary

Each hierarchy operation may have an associated a view and trigger.

| <center>Group</center> | <center>Operation</center> | <center>`op_name`</center> | <center>Description</center>                                                             |
| ---------------------- | -------------------------- | -------------------------- | ---------------------------------------------------------------------------------------- |
| DELETE                 | Categories                 | `del_cat`                  | Given a set of categories, delete the associated subtrees and related item associations. |
| DELETE                 | Item associations          | `del_item_cat`             | Given a category and a set of associated items, remove items from the category.          |
| DELETE                 | Item associations reset    | `reset_item_cat`           | Given a set of items, remove all related category associations.                          |
| DELETE                 | Items                      | `del_item`                 | Given a set of items, delete them.                                                       |

---
---

## Categories - `del_cat`

Given a set of categories, delete the associated subtrees and related item associations

### View

```sql
-- Prepares the list of categories to be deleted
DROP VIEW IF EXISTS "del_cat";
CREATE VIEW "del_cat" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'del_cat'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            value AS path
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    )
SELECT path FROM base_ops;
```

### Trigger

```sql
-- Deletes categories
DROP TRIGGER IF EXISTS "del_cat";
CREATE TRIGGER "del_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'del_cat'
BEGIN
    UPDATE categories SET flag = 'deleted' FROM del_cat
    WHERE categories.path || '/' LIKE del_cat.path || '/%';
    DELETE FROM categories WHERE flag = 'deleted';
END;
```

Cascading foreign keys make sure that category subtrees and related item association are deleted. (Note, the present code with prefix matching explicitly deletes all target categories. It is sufficient to delete just the specified categories by matching their paths exactly.) Items remain otherwise unaffected.

### Dummy data

```sql
-- Data for categories to be deleted
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('del_cat', json('
                [
                    "/Assets/Diagrams",
                    "/Library/Drafts/DllTools/Dem - DLL/memtools",
                    "/Project/SQLiteDBdev",
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```




## Item Associations - `del_item_cat`

Given a category and a set of associated items, remove items from the category

### View

```sql
-- Prepares the list of categories to be deleted
DROP VIEW IF EXISTS "del_item_cat";
CREATE VIEW "del_item_cat" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'del_item_cat'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            jo.json_op ->> '$.cat_path' AS cat_path,
            value AS item_handle
        FROM
            json_ops AS jo,
            json_each(jo.json_op ->> '$.item_handles') AS terms
    )
SELECT * FROM base_ops;
```

### Trigger

```sql
-- Deletes categories
DROP TRIGGER IF EXISTS "del_item_cat";
CREATE TRIGGER "del_item_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'del_item_cat'
BEGIN
    DELETE FROM items_categories
    WHERE (cat_path, item_handle) IN (SELECT * FROM del_item_cat);
END;
```

### Dummy data

```sql
-- Data for item associations to be deleted
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('del_item_cat', json('{
                "cat_path": "/Assets/Diagrams",
                "item_handles": [
                    "115d7db97e71b4ebba0388009cbf514b",
                    "25c7d52190cb287ce5333fbfb55fa62c",
                    "263d97ba77c87d8ff662c1cf471a54e3",
                    "26461fd16a254e5d7f54afa88a35ddf1",
                    "2b6292a5ce9f377df08da4687cb3eed8",
                    "305391763051ed220149f52f90cfa869",
                    "37befb150ae33ae8e0f7467ad9898c48",
                    "396e16c24fbade080482aaf84ef63cc5",
                    "5e26004e2f286e8e2d166bd8fc2f7684",
                ]            
            }'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Reset Item Associations - `reset_item_cat`

Given a set of items, remove all related category associations.

### View

```sql
-- Prepares the list of item associations to be reset
DROP VIEW IF EXISTS "reset_item_cat";
CREATE VIEW "reset_item_cat" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'reset_item_cat'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            value AS item_handle
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    )
SELECT * FROM base_ops;
```

### Trigger

```sql
-- Resets item associations
DROP TRIGGER IF EXISTS "reset_item_cat";
CREATE TRIGGER "reset_item_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'reset_item_cat'
BEGIN
    DELETE FROM items_categories
    WHERE item_handle IN (SELECT * FROM reset_item_cat);
END;
```

### Dummy data

```sql
-- Data for item associations to be reset
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('reset_item_cat', json('
                [
                    "0764037c54441d43fc57d370dfe203e6",
                    "09ec2bbbb61735163017bee90e46aaed",
                    "2b25a438f79f9449101a5cb5abdb4d5f",
                    "396e16c24fbade080482aaf84ef63cc5",
                    "5f073b688ca9cf337876eea52afc04f5",
                    "5f6532836598595c39d75e403cff769f",
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Delete Items - `del_item`

Given a set of items, delete them.

### View

```sql
-- Prepares the list of items to be deleted
DROP VIEW IF EXISTS "del_item";
CREATE VIEW "del_item" AS
WITH
    json_ops AS (
		SELECT json_op
		FROM hierarchy_ops
		WHERE op_name = 'del_item'
		ORDER BY id DESC
		LIMIT 1
    ),
    base_ops AS (
        SELECT
            value AS item_handle
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    )
SELECT * FROM base_ops;
```

### Trigger

```sql
-- Deletes items
DROP TRIGGER IF EXISTS "del_item";
CREATE TRIGGER "del_item"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'del_item'
BEGIN
    DELETE FROM items
    WHERE item_handle IN (SELECT * FROM del_item);
END;
```

### Dummy data

```sql
-- Data for items to be deleted
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('del_item', json('
                [
                    "0764037c54441d43fc57d370dfe203e6",
                    "09ec2bbbb61735163017bee90e46aaed",
                    "2b25a438f79f9449101a5cb5abdb4d5f",
                    "396e16c24fbade080482aaf84ef63cc5",
                    "5f073b688ca9cf337876eea52afc04f5",
                    "5f6532836598595c39d75e403cff769f",
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

---

| [**<= CREATE Operations**][CREATE] | [**Next: MODIFY Operations =>**][MODIFY] |
| ---------------------------------- | ---------------------------------------- |


<!-- References -->

[CREATE]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopCREATE.md
[MODIFY]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopMODIFY.md
