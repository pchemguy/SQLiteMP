--------------------------------------------------------------------------------
--------------------------------- MPopDELETE.md --------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ## Categories - `del_cat`
-- Given a set of categories, delete the associated subtrees and related item associations
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Item Associations - `del_item_cat`
-- Given a category and a set of associated items, remove items from the category
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Reset Item Associations - `reset_item_cat`
-- Given a set of items, remove all related category associations.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```

--------------------------------------------------------------------------------
-- ## Delete Items - `del_item`
-- Given a set of items, delete them.
--------------------------------------------------------------------------------

-- ```sql
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
-- ```

-- ```sql
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
-- ```
