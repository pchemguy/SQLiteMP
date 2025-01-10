--------------------------------------------------------------------------------
--------------------------------- MPopMODIFY.md --------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- ## Move Item Associations - `mv_item_cat`
-- Given a set of items, and source and destination categories, replace item associations from source to destination (other associations remain unaffected).
--------------------------------------------------------------------------------

-- ```sql
-- Prepares the list of categories to be moved
DROP VIEW IF EXISTS "mv_item_cat";
CREATE VIEW "mv_item_cat" AS
WITH
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'mv_item_cat'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops AS (
        SELECT
            jo.json_op ->> '$.cat_path' AS cat_path,
            jo.json_op ->> '$.new_path' AS new_path,
            value AS item_handle
        FROM
            json_ops AS jo,
            json_each(jo.json_op ->> '$.item_handles') AS terms
    )
SELECT * FROM base_ops;
-- ```

-- ```sql
-- Moves categories
DROP TRIGGER IF EXISTS "mv_item_cat";
CREATE TRIGGER "mv_item_cat"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'mv_item_cat'
BEGIN
    UPDATE items_categories
    SET cat_path = mv.new_path
    FROM mv_item_cat AS mv
    WHERE mv.cat_path    = items_categories.cat_path
      AND mv.item_handle = items_categories.item_handle;
END;
-- ```

--------------------------------------------------------------------------------
-- ## Move Trees - `mv_tree`
-- Given a set of categories and associated new paths, move subtrees and update related item associations.
--------------------------------------------------------------------------------

-- ```sql
-- Prepares the list of categories to be moved
DROP VIEW IF EXISTS "mv_tree";
CREATE VIEW "mv_tree" AS
WITH RECURSIVE
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'mv_tree'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            '/' || trim(json_extract(value, '$.path_old'), '/') AS rootpath_old,
            '/' || trim(json_extract(value, '$.path_new'), '/') AS rootpath_new
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    /********************************************************************/
    --------------------------- SUBTREES LIST ----------------------------
    subtrees_old AS (
        SELECT opid, ascii_id, path AS path_old
        FROM base_ops, categories
        WHERE path_old || '/' LIKE rootpath_old || '/%'
        ORDER BY opid, path_old
    ),
    /********************************************************************/
    ----------------------------- MOVE LOOP ------------------------------
    LOOP_MOVE AS (
            SELECT 0 AS opid, ascii_id, path_old AS path_moved
            FROM subtrees_old
        UNION ALL
            SELECT ops.opid, lp.ascii_id,
                   iif(lp.path_moved || '/' NOT LIKE ops.rootpath_old || '/%', lp.path_moved,
                       ops.rootpath_new || substr(lp.path_moved, length(ops.rootpath_old) + 1)
                   ) AS path_moved
            FROM LOOP_MOVE AS lp, base_ops AS ops
            WHERE ops.opid = lp.opid + 1
    ),
    /********************************************************************/
    subtrees_new_base AS (
        SELECT ascii_id, path_moved AS path_new,
               json_extract('["' || replace(trim(path_moved, '/'), '/', '", "') || '"]', '$[#-1]') AS name_new
        FROM LOOP_MOVE
        WHERE opid = (SELECT max(base_ops.opid) FROM base_ops)
    ),
    subtrees_path AS (
        SELECT
            (row_number() OVER (ORDER BY path_old)) AS priority,
            trnew.ascii_id, path_old, path_new,
            substr(path_new, 1, length(path_new) - length(name_new) - 1) AS prefix_new,
            name_new
        FROM subtrees_new_base AS trnew, subtrees_old AS trold
        WHERE trnew.ascii_id = trold.ascii_id
          AND path_old <> path_new
    ),
    new_paths AS (
        SELECT
            subtrees_path.*,
            (cats.ascii_id IS NOT NULL) + (row_number() OVER (PARTITION BY path_new ORDER BY priority) - 1) AS target_exists
        FROM subtrees_path LEFT JOIN categories AS cats ON path_new = path
    )
SELECT
    ascii_id, path_old, path_new,
    iif(prefix_new <> '', prefix_new, NULL) AS prefix_new,
    name_new, target_exists
FROM new_paths
ORDER BY target_exists, path_old;
-- ```

-- ```sql
-- Moves categories
DROP TRIGGER IF EXISTS "mv_tree";
CREATE TRIGGER "mv_tree"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'mv_tree'
BEGIN
    UPDATE OR IGNORE "categories" SET (name, parent_path) = (name_new, prefix_new)
    FROM mv_tree AS mvt
    WHERE mvt.target_exists = 0
      AND mvt.path_old = categories.path;    

    -- Update association tables
    UPDATE "items_categories" SET cat_path = path_new
    FROM mv_tree AS mvt
    WHERE mvt.target_exists > 0
      AND mvt.path_old = cat_path;
      
    -- Delete source categories colliding with existing destination
    DELETE FROM "categories"
    WHERE path IN (
        SELECT path_old
        FROM mv_tree AS mvt
        WHERE mvt.target_exists > 0
    );
END;
-- ```

--------------------------------------------------------------------------------
-- ## Copy Trees - `cp_tree`
-- Given a set of categories and associated new paths, copy subtrees and update related item associations.
--------------------------------------------------------------------------------

-- ```sql
-- Prepares the list of categories to be copied
DROP VIEW IF EXISTS "cp_tree";
CREATE VIEW "cp_tree" AS
WITH RECURSIVE
    ------------------------------ PROLOGUE ------------------------------
    json_ops AS (
        SELECT json_op
        FROM hierarchy_ops
        WHERE op_name = 'cp_tree'
        ORDER BY id DESC
        LIMIT 1
    ),
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            '/' || trim(json_extract(value, '$.path_old'), '/') AS rootpath_old,
            '/' || trim(json_extract(value, '$.path_new'), '/') AS rootpath_new
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    /********************************************************************/
    --------------------------- SUBTREES LIST ----------------------------
    subtrees_old AS (
        SELECT ops.opid, c.path AS path_old, c.path AS src_path
        FROM base_ops AS ops, categories AS c
        WHERE path_old || '/' LIKE ops.rootpath_old || '/%'
        GROUP BY ops.opid, path_old
        ORDER BY ops.opid, path_old
    ),
    /********************************************************************/
    ----------------------------- COPY LOOP ------------------------------
    LOOP_COPY AS (
            SELECT 0 AS opid, NULL AS path_new, NULL AS src_path, json('[]') AS oplog
        UNION ALL
            SELECT ops.opid, lc.path_new, lc.src_path, lc.oplog
            FROM LOOP_COPY AS lc, base_ops AS ops
            WHERE ops.opid = lc.opid + 1
        UNION ALL
            SELECT
                ops.opid,
                ops.rootpath_new || substr(so.path_old, length(ops.rootpath_old) + 1) AS path_new,
				so.src_path,
                json_set(lc.oplog, '$[#]', ops.opid) AS oplog
            FROM LOOP_COPY AS lc, base_ops AS ops, subtrees_old AS so
            WHERE lc.path_new IS NULL
              AND ops.opid = lc.opid + 1
              AND so.opid = lc.opid + 1
        UNION ALL
            SELECT
                ops.opid,
                ops.rootpath_new || substr(lc.path_new, length(ops.rootpath_old) + 1) AS path_new,
				lc.src_path,
                json_set(lc.oplog, '$[#]', ops.opid) AS oplog
            FROM LOOP_COPY AS lc, base_ops AS ops
            WHERE ops.opid = lc.opid + 1
              AND lc.path_new || '/' LIKE ops.rootpath_old || '/%'
    ),
    /********************************************************************/
    truncated_src_path AS (
        SELECT opid, path_new, src_path, oplog
        FROM LOOP_COPY
        WHERE NOT path_new IS NULL
          AND opid = (SELECT max(opid) FROM base_ops)
        ORDER BY path_new
    ),
    truncated AS (
        SELECT
			tsp.opid,
			NULL AS ascii_id,
			tsp.path_new,
			json_group_array(ic.item_handle ORDER BY ic.item_handle) AS item_handles,
			tsp.oplog
		FROM truncated_src_path  AS tsp, items_categories AS ic
		WHERE tsp.src_path = ic.cat_path
		GROUP BY tsp.path_new, tsp.src_path
	),
    subtrees_path AS (
        SELECT
            group_concat(ascii_id) AS ascii_id,
            path_new,
            replace(group_concat(iif(item_handles <> '[]', item_handles, NULL), ''), '][', ',') AS item_handles,
            replace(group_concat(iif(oplog <> '[]', oplog, NULL), ''), '][', ',') AS oplog
        FROM truncated
        GROUP BY path_new
        ORDER BY path_new
    ),
    collisions AS (
        SELECT categories.ascii_id, path_new, item_handles
        FROM subtrees_path
        LEFT JOIN categories ON path_new = path
    ),
    subtrees_names AS (
        SELECT
            ascii_id,
            json_extract('["' || replace(trim(path_new, '/'), '/', '", "') || '"]', '$[#-1]') AS name_new,
            path_new,
            item_handles
        FROM collisions
    ),
    new_paths AS (
            SELECT
                NULL counter, ascii_id, NULL AS prefix_new, NULL AS name_new, path_new, item_handles
            FROM subtrees_names
            WHERE NOT ascii_id IS NULL
        UNION ALL
            SELECT
                row_number() OVER (ORDER BY path_new) - 1 AS counter,
                ascii_id,
                iif(length(path_new) - length(name_new) - 1 > 0,
                    substr(path_new, 1, length(path_new) - length(name_new) - 1),
                    NULL
                ) AS prefix_new,
                name_new,
                path_new,
                item_handles
            FROM subtrees_names
            WHERE ascii_id IS NULL
    ),
    ------------------------- ASCII ID GENERATOR -------------------------
    -- IMPORTANT: This code generates pseudorandom id's but it does not check for potential collisions.
    ---------------------------------------------------------------------------------------------------
    id_counts(id_counter) AS (SELECT count(new_paths.counter) FROM new_paths),
    json_templates AS (SELECT '[' || replace(hex(zeroblob(id_counter*8/2-1)), '0', '0,') || '0,0]' AS json_template FROM id_counts),
    char_templates(char_template) AS (VALUES ('0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzAa')),
    ascii_ids AS (
        SELECT group_concat(substr(char_template, (random() & 63) + 1, 1), '') AS ascii_id, "key"/8 AS counter
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
    target_nodes AS (
        SELECT bin_id AS id, prefix_new AS prefix, name_new AS name, path_new AS path, item_handles
        FROM new_paths
        LEFT JOIN ids USING (counter)
    )
SELECT * FROM target_nodes
ORDER BY (NOT id IS NULL), path;
-- ```

-- ```sql
-- Copies categories
DROP TRIGGER IF EXISTS "cp_tree";
CREATE TRIGGER "cp_tree"
AFTER INSERT ON "hierarchy_ops"
FOR EACH ROW
WHEN NEW."op_name" = 'cp_tree'
BEGIN
    INSERT INTO categories(id, name, parent_path)
    SELECT id, name, prefix AS parent_path FROM cp_tree
    WHERE NOT name IS NULL;
    
    INSERT OR IGNORE INTO items_categories(cat_path, item_handle)
    SELECT cp_tree.path AS cat_path, assoc.value AS item_handle
    FROM cp_tree, json_each(item_handles) AS assoc;
END;
-- ```
