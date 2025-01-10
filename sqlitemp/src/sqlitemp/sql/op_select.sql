--------------------------------------------------------------------------------
--------------------------------- MPopSELECT.md --------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ## Descendant Categories - `ls_cat_desc`
-- Given a set of categories, retrieve the set of descendant categories.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Child Categories - `ls_cat_child`
-- Given a set of categories, retrieve the set of child categories.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Empty Categories - `ls_cat_empty`
-- Retrieve all empty categories.
--------------------------------------------------------------------------------

-- ```sql
-- Retrieves empty categories
DROP VIEW IF EXISTS "ls_cat_empty";
CREATE VIEW "ls_cat_empty" AS
SELECT c.path
FROM categories AS c
LEFT JOIN items_categories AS ic
ON c.path = ic.cat_path
WHERE ic.cat_path IS NULL
ORDER BY c.path;
-- ```

-- ```sql
-- Retrieves empty categories
DROP TRIGGER IF EXISTS "ls_cat_empty";
CREATE TRIGGER "ls_cat_empty"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_cat_empty'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(path ORDER BY path) AS json_data
        FROM ls_cat_empty
    )
	WHERE id = NEW.id;
END;
-- ```

--------------------------------------------------------------------------------
-- ## Descendant Items - `ls_item_desc`
-- Given a set of categories, retrieve the set of items associated with subtrees.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
-- Retrieves descendant items
DROP TRIGGER IF EXISTS "ls_item_desc";
CREATE TRIGGER "ls_item_desc"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_item_desc'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(handle ORDER BY name) AS json_data
        FROM ls_item_desc
    )
	WHERE id = NEW.id;
END;
-- ```

--------------------------------------------------------------------------------
-- ## Child Items - `ls_item_desc`
-- Given a set of categories, retrieve the set of directly associated items.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
-- Retrieves child items
DROP TRIGGER IF EXISTS "ls_item_child";
CREATE TRIGGER "ls_item_child"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_item_child'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(handle ORDER BY name) AS json_data
        FROM ls_item_child
    )
	WHERE id = NEW.id;
END;

--------------------------------------------------------------------------------
-- ## Unfiled Items - `ls_item_unfiled`
-- Retrieve all unfiled items.
--------------------------------------------------------------------------------

-- Retrieves child items
DROP VIEW IF EXISTS "ls_item_unfiled";
CREATE VIEW "ls_item_unfiled" AS
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
ORDER BY i.name;
-- ```

-- ```sql
-- Retrieves child items
DROP TRIGGER IF EXISTS "ls_item_unfiled";
CREATE TRIGGER "ls_item_unfiled"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'ls_item_unfiled'
BEGIN
    UPDATE hierarchy_ops SET payload = json_data
    FROM (
        SELECT json_group_array(json(item_data) ORDER BY item_data) AS json_data
        FROM ls_item_unfiled
    )
	WHERE id = NEW.id;
END;
-- ```

--------------------------------------------------------------------------------
-- ## Item Associations - `ls_item_cat`
-- Given an item, retrieve the set of associated categories.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Item Association Counts - `cnt_item_cat`
-- Given a set of items, retrieve the number of categories associated with each item
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Child Items  Association Counts - `cnt_item_child_cat`
-- Given a category, retrieve *item association counts* for all directly associated items.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```
