# EXPORT Operations

## Summary

Each hierarchy operation may have an associated a view and trigger.

| <center>Group</center> | <center>Operation</center> | <center>`op_name`</center> | <center>Description</center>                                                                                          |
| ---------------------- | -------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| EXPORT                 | Categories                 | `exp_cat`                  | Given a set of categories, export paths for associated trees. If no categories are specified, export the entire tree. |
| EXPORT                 | Leaf categories            | `exp_cat_leaf`             | Export leaf categories.                                                                                               |
| EXPORT                 | Items                      | `exp_item`                 | Export items.                                                                                                         |
| EXPORT                 | Item associations          | `exp_item_cat`             | Export item associations.                                                                                             |
| EXPORT                 | Core data                  | `exp_core`                 | Export categories, items, an associations                                                                             |

---
---

## Categories - `exp_cat`

Given a set of categories, export paths for associated trees. If no categories are specified, export the entire tree.

### View

```sql
-- Prepares the list of target categories
WITH
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'exp_cat'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops AS (
        SELECT
            value AS path
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    nodes AS (
            SELECT categories.path
            FROM categories, base_ops
            WHERE (SELECT count(*) FROM base_ops) > 0
              AND categories.parent_path || '/' LIKE base_ops.path || '/%'
        UNION ALL
            SELECT categories.path
            FROM categories
            WHERE (SELECT count(*) FROM base_ops) = 0
    )
SELECT * FROM nodes
ORDER BY path;
```

### Trigger

```sql
-- Export categories
DROP TRIGGER IF EXISTS "exp_cat";
CREATE TRIGGER "exp_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'exp_cat'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY path) AS json_data
        FROM exp_cat
    )
	WHERE id = NEW.id;
END;
```

### Dummy data

```sql
-- Data for exporting categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('exp_cat', json('[
                "/Assets/Diagrams",
                "/Library/Drafts/DllTools/Dem - DLL/memtools",
                "/Project/SQLiteDBdev",
            ]'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Leaf categories - `exp_cat_leaf`

Export leaf categories.

### View

```sql
-- Prepares list of leaf categories
DROP VIEW IF EXISTS "exp_cat_leaf";
CREATE VIEW "exp_cat_leaf" AS
SELECT path
FROM categories
WHERE path NOT IN (
    SELECT parent_path
    FROM categories
    WHERE NOT parent_path IS NULL
)
ORDER BY path;
```

### Trigger

```sql
-- Export categories
DROP TRIGGER IF EXISTS "exp_cat_leaf";
CREATE TRIGGER "exp_cat_leaf"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'exp_cat_leaf'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY path) AS json_data
        FROM exp_cat_leaf
    )
	WHERE id = NEW.id;
END;
```

## Items - `exp_item`

Export items.

### View

```sql
-- Prepares JSON-packed item data
DROP VIEW IF EXISTS "exp_item";
CREATE VIEW "exp_item" AS
SELECT
	json_group_array(json_object(
		'name', name,
		'handle_type', handle_type,
		'handle', handle
	) ORDER BY name) AS payload
FROM items;
```

### Trigger

```sql
-- Export items
DROP TRIGGER IF EXISTS "exp_item";
CREATE TRIGGER "exp_item"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'exp_item'
BEGIN
    UPDATE hierarchy_ops SET payload = exp_item.payload
    FROM exp_item
	WHERE id = NEW.id;
END;
```

## Item associations - `exp_item_cat`

Export item associations..

### View

```sql
-- Prepares item data list
DROP VIEW IF EXISTS "exp_item_cat";
CREATE VIEW "exp_item_cat" AS
SELECT cat_path, json_group_array(item_handle ORDER BY name) AS item_handles
FROM items_categories, items
WHERE item_handle = handle
GROUP BY cat_path;
```

### Trigger

```sql
-- Export items
DROP TRIGGER IF EXISTS "exp_item_cat";
CREATE TRIGGER "exp_item_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'exp_item_cat'
BEGIN
    UPDATE hierarchy_ops SET payload = data.payload
    FROM (
        SELECT
            json_group_array(json_object(
                'cat_path', cat_path,
                'item_handlea', json(item_handles)
            ) ORDER BY cat_path) AS payload
        FROM exp_item_cat
    ) AS data
	WHERE id = NEW.id;
END;
```

## Core data - `exp_core`

Export categories, items, an associations

### View

```sql
-- Prepares partially packed core data
DROP VIEW IF EXISTS "exp_core";
CREATE VIEW "exp_core" AS
WITH
    empty_cats AS (
        SELECT c.path
        FROM categories AS c
        LEFT JOIN items_categories AS ic
        ON c.path = ic.cat_path
        WHERE ic.cat_path IS NULL
        ORDER BY c.path
    ),
    unfiled_items AS (
        SELECT
            json_object(
                'name', i.name,
                'handle_type', i.handle_type,
                'handle', i.handle
            ) AS item_data
        FROM items AS i
        LEFT JOIN items_categories AS ic
        ON i.handle = ic.item_handle
        WHERE ic.item_handle IS NULL
        ORDER BY i.name
    ),
    associated AS (
        SELECT
            c.path,
            json_group_array(json_object(
                'name', i.name,
                'handle_type', i.handle_type,
                'handle', i.handle
            ) ORDER BY i.name) AS item_data
        FROM categories AS c, items AS i, items_categories AS ic
        WHERE (c.path, i.handle) = (ic.cat_path, ic.item_handle)
        GROUP BY ic.cat_path
        ORDER BY c.path
    ),
    package AS (
        SELECT
            json_object(
                'empty_cats', (
                    SELECT json_group_array(path ORDER BY path) FROM empty_cats
                ),
                'unfiled_items', (
                    SELECT json_group_array(json(item_data) ORDER BY item_data) FROM unfiled_items
                ),
                'associated', (
                    SELECT
                        json_group_array(json_object(
                            'path', path,
                            'item_data', json(item_data)
                        ) ORDER BY path)
                    FROM associated
                )
            ) AS core_data
    )
SELECT * FROM package;
```

### Trigger

```sql
-- Export items
DROP TRIGGER IF EXISTS "exp_core";
CREATE TRIGGER "exp_core"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'exp_core'
BEGIN
    UPDATE hierarchy_ops SET payload = core_data
    FROM exp_core
	WHERE id = NEW.id;
END;
```

---

| [**<= MODIFY Operations**][MODIFY] |
| ---------------------------------- |

<!-- References -->

[MODIFY]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopMODIFY.md
