--------------------------------------------------------------------------------
--------------------------------- MPopCREATE.md --------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ## Categories - `new_cat`
-- Given a set of paths, create all necessary categories.
--------------------------------------------------------------------------------

-- ```sql
-- Prepares the list of new categories
DROP VIEW IF EXISTS "new_cat";
CREATE VIEW "new_cat" AS
WITH
    ------------------------------ PROLOGUE ------------------------------
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'new_cat'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            json_extract(value, '$.path') AS path
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    /********************************************************************/
    --------------------------- ANCESTOR LIST ----------------------------
    levels AS (
        SELECT opid, path, length(path) - length(replace(path, '/', '')) AS depth
        FROM base_ops
    ),
    json_objs AS (
        SELECT *, json('{"' || replace(trim(path, '/'), '/', '": {"') ||
            '":""' || replace(hex(zeroblob(depth)), '00', '}')) AS json_obj
        FROM levels
    ),
    ancestors AS (
        SELECT min(jo.opid) AS opid,
            '/' || replace(replace(replace(substr(fullkey, 3), '.', '/'), '^#^', '.'), '"', '') AS path_new,
            replace("key", '^#^', '.') AS name_new
        FROM
            json_objs AS jo,
            json_tree(replace(jo.json_obj, '.', '^#^')) AS terms
        WHERE terms.parent IS NOT NULL
        GROUP BY path_new
        ORDER BY opid, path_new
    ),
    /********************************************************************/
    filtered_terms AS (
        SELECT
            row_number() OVER (ORDER BY opid, path_new) AS counter,
            ancestors.*, substr(path_new, 1, length(path_new) - length(name_new) - 1) AS parent_path
        FROM ancestors
        LEFT JOIN categories AS cats ON path_new = cats.path
        WHERE cats.ascii_id IS NULL
    ),
    ------------------------- ASCII ID GENERATOR -------------------------
    -- IMPORTANT: This code generates pseudorandom id's but it does not check for potential collisions.
    ---------------------------------------------------------------------------------------------------
    id_counts(id_counter) AS (SELECT count(*) FROM filtered_terms),
    json_templates AS (SELECT '[' || replace(hex(zeroblob(id_counter*8/2-1)), '0', '0,') || '0,0]' AS json_template FROM id_counts),
    char_templates(char_template) AS (VALUES ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzAa')),
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
    ),
    /********************************************************************/
    nodes AS (
        SELECT
            bin_id AS id,
            iif(length(parent_path) > 0, parent_path, NULL) AS parent_path,
            name_new AS name
        FROM filtered_terms, ids USING (counter)
    )
SELECT * FROM nodes
ORDER BY lower(ifnull(parent_path, '') || '/' || name);
-- ```

-- ```sql
-- Generates new categories
DROP TRIGGER IF EXISTS "new_cat";
CREATE TRIGGER "new_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'new_cat'
BEGIN
    INSERT INTO categories(id, name, parent_path)
    SELECT id, name, parent_path FROM new_cat;
END;
-- ```

--------------------------------------------------------------------------------
-- ## Items - `new_item`
-- Given a set of items, add them to the `items` table.
--------------------------------------------------------------------------------

-- ```sql
-- Prepares the list of new items
DROP VIEW IF EXISTS "new_item";
CREATE VIEW "new_item" AS
WITH
    ------------------------------ PROLOGUE ------------------------------
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'new_item'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            json_extract(value, '$.name') AS name,
            json_extract(value, '$.handle_type') AS handle_type,
            json_extract(value, '$.handle') AS handle
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    /********************************************************************/
    filtered_terms AS (
        SELECT
            row_number() OVER (ORDER BY opid) AS counter,
            base_ops.name, base_ops.handle_type, base_ops.handle
        FROM base_ops
        LEFT JOIN items USING (handle)
        WHERE items.ascii_id IS NULL
    ),
    ------------------------- ASCII ID GENERATOR -------------------------
    id_counts(id_counter) AS (SELECT count(*) FROM base_ops),
    json_templates AS (SELECT '[' || replace(hex(zeroblob(id_counter*8/2-1)), '0', '0,') || '0,0]' AS json_template FROM id_counts),
    char_templates(char_template) AS (VALUES ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzAa')),
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
    ),
    /********************************************************************/
    nodes AS (
        SELECT bin_id AS id, name, handle_type, handle
        FROM filtered_terms, ids USING (counter)
    )
SELECT id, name, handle_type, handle FROM nodes
ORDER BY lower(name);
-- ```

-- ```sql
-- Generates new items
DROP TRIGGER IF EXISTS "new_item";
CREATE TRIGGER "new_item"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'new_item'
BEGIN
    INSERT INTO items(id, name, handle_type, handle)
    SELECT id, name, handle_type, handle FROM new_item;
END;
-- ```

--------------------------------------------------------------------------------
-- ## Item Associations - `new_item_cat`
-- Given a set of item associations, add information to the association table.
--------------------------------------------------------------------------------

-- ```sql
-- Prepares the list of new item associations
DROP VIEW IF EXISTS "new_item_cat";
CREATE VIEW "new_item_cat" AS
WITH
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'new_item_cat'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops_packed AS (
        SELECT
            "key" + 1 AS opid,
            json_extract(value, '$.cat_path') AS cat_path,
            json_extract(value, '$.item_handles') AS item_handles
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    base_ops AS (
        SELECT opid, cat_path, value AS item_handle
        FROM base_ops_packed AS bop, json_each(bop.item_handles) AS terms
    ),
    filtered_terms AS (
        SELECT base_ops.cat_path, base_ops.item_handle
        FROM base_ops
        LEFT JOIN items_categories USING (cat_path, item_handle)
        WHERE items_categories.item_handle IS NULL
    )
SELECT cat_path, item_handle
FROM filtered_terms
ORDER BY lower(cat_path), item_handle;
-- ```

-- ```sql
-- Generates new item associations
DROP TRIGGER IF EXISTS "new_item_cat";
CREATE TRIGGER "new_item_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'new_item_cat'
BEGIN
    INSERT INTO items_categories(cat_path, item_handle)
    SELECT cat_path, item_handle FROM new_item_cat;
END;
-- ```
