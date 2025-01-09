# MODIFY Operations

## Summary

Each hierarchy operation may have an associated a view and trigger.


| <center>Group</center> | <center>Operation</center> | <center>`op_name`</center> | <center>Description</center>                                                                                                                              |
| ---------------------- | -------------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MODIFY                 | Move item associations     | `mv_item_cat`              | Given a set of items, and source and destination categories, replace item associations from source to destination (other associations remain unaffected). |
| MODIFY                 | Move trees                 | `mv_tree`                  | Given a set of categories and associated new paths, move subtrees and update related item associations.                                                   |
| MODIFY                 | Copy trees                 | `cp_tree`                  | Given a set of categories and associated new paths, copy subtrees and update related item associations.                                                   |


---
---

## Move Item Associations - `mv_item_cat`

Given a set of items, and source and destination categories, replace item associations from source to destination (other associations remain unaffected).

### View

```sql
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
```

### Trigger

```sql
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
```

### Dummy data

```sql
-- Data for item associations to be moved
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('mv_item_cat', json('{
                "cat_path": "/Assets/Diagrams",
                "new_path": "/Project/SQLite",                
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

## Move Trees - `mv_tree`

Given a set of categories and associated new paths, move subtrees and update related item associations.

### View

```sql
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
```

### Code Walkthrough

The current implementation supports a *compound* move operation, where multiple categories can be moved sequentially, making the associated code relatively complex. In practice, each "atomic" operation can be persisted by the application individually, even when multiple nodes are being moved. Code for persisting a single move/copy operation is simpler. The primary motivations for implementing the code presented here were to test the feasibility of such an approach and to practice SQL coding.

The **`json_ops`** and **`base_ops`** Common Table Expressions (CTEs) unpack JSON-formatted input (refer to the **Dummy Data** section below) into a table, where each row describes a single operation as a combination of **`path_old`** and **`path_new`** values. Additionally, the **`base_ops`** CTE performs basic path normalization by trimming leading and trailing slashes, if present, and adding a leading slash:

```sql
'/' || trim(json_extract(value, '$.path_old'), '/')
```

#### Move Operation Behavior

The move operation cannot create new categories, unlike the copy operation. When a category is moved, its `parent_path` and/or `name` fields need to be updated, along with the `parent_path` fields of its descendants. Although the foreign key on `parent_path` is set for cascading updates, the current implementation explicitly updates all affected categories to address potential name collisions. There is potential for optimization to reduce redundant updates to descendant categories. In cases of name collisions, the move operation deletes the category being moved and merges its item associations with the existing destination category, following the "*keep existing destination*" convention.

 **`subtrees_old`**
Only categories with a `path_old` prefix in their `path` field are affected by the move operation. For compound moves, earlier operations may affect subsequent operations. Consequently, the selection of all categories with prefixes matching any `path_old` constitutes the complete set of "affected" categories. Existing categories are not directly modified due to the "*keep existing destination*" rule. The **`subtrees_old`** CTE generates this list of affected categories. 

#### **`LOOP_MOVE`**

The **`LOOP_MOVE`** CTE is recursive and the most complex component of this implementation (see also this [RCTE tutorial][rec-cte]). It sequentially applies all requested move operations to the prepared set of affected nodes. Intermediate states of the category tree and item associations are ignored, as only the final new path for each category is required to update the target database tables correctly.

Key logic in **`LOOP_MOVE`**:

```sql
iif(lp.path_moved || '/' NOT LIKE ops.rootpath_old || '/%', lp.path_moved,
   ops.rootpath_new || substr(lp.path_moved, length(ops.rootpath_old) + 1)
) AS path_moved
```

The extra slash ensures accurate prefix matching, avoiding unintended matches. The `replace()` function is not used to prevent incorrect substitutions of `rootpath_old` in the middle of `path_moved`.

#### Handling Collisions

The **`subtrees_new_base`** and **`subtrees_path`** CTEs perform filtering and generate the `name` and `parent_path` for new categories. The following line assigns priority to each `path_old` based on its sorted position:

```sql
(row_number() OVER (ORDER BY path_old)) AS priority
```

This priority ensures proper processing of operations involving colliding categories, accounting for cascading updates and internal collisions in the affected category list.

The **`new_paths`** CTE identifies colliding categories, ensuring that preserved categories originate from the same subtree when internal collisions occur.

#### Trigger Code

The trigger code executes in the following sequence:
1. **Update Non-Colliding Categories**: Categories without name collisions are updated first. Item associations for these categories remain unaffected.
2. **Handle Colliding Categories**: Item associations for categories to be deleted are updated. When both colliding categories share the same items, primary key violations in the `items_categories` table are handled automatically by the `ON CONFLICT REPLACE` clause.
3. **Delete Colliding Categories**: Finally, the source colliding categories are removed.

This approach ensures consistent and efficient processing of compound move operations while handling potential collisions and maintaining data integrity.

### Trigger

```sql
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
```

### Dummy data

```sql
-- Data for tree move
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('mv_tree', json('[
                {"path_old":"/BAZ/bld/booze/safe00",     "path_new":"/bbbbbb"},
                {"path_old":"/BAZ/bld/tcl/tests/safe00", "path_new":"/safe00"},
                {"path_old":"/safe00",                   "path_new":"/safe"},
                {"path_old":"/BAZ/dev/msys2",            "path_new":"/BAZ/dev/msys"},
                {"path_old":"/BAZ/bld/tcl/tests/preEEE", "path_new":"/preEEE"},
                {"path_old":"/safe/modules",             "path_new":"/safe/modu"},
                {"path_old":"/safe/modu/mod2",           "path_new":"/safe/modu/mod3"},
                {"path_old":"/BAZ/bld/tcl/tests/ssub00", "path_new":"/safe/ssub00"},
                {"path_old":"/BAZ/dev/msys/mingw32",     "path_new":"/BAZ/dev/msys/nix"},
                {"path_old":"/safe/ssub00/modules",      "path_new":"/safe/modules"},
                {"path_old":"/BAZ/bld/tcl/tests/manYYY", "path_new":"/man000"},
                {"path_old":"/BAZ/dev/msys/nix/etc",     "path_new":"/BAZ/dev/msys/nix/misc"},
                {"path_old":"/BAZ/bld/tcl/tests/manZZZ", "path_new":"/BAZ/bld/tcl/tests/man000"},
                {"path_old":"/BAZ/bld/tcl/tests/man000", "path_new":"/man000"},
                {"path_old":"/BAZ/bld/tcl/tests/safe11", "path_new":"/safe11"},
            ]'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

## Copy Trees - cp_tree`

Given a set of categories and associated new paths, copy subtrees and update related item associations.

### View

```sql
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
        SELECT opid, path AS path_old, json_group_array(item_handle) AS item_handles
        FROM base_ops, categories, items_categories
        WHERE path_old || '/' LIKE rootpath_old || '/%'
          AND path_old = cat_path
        GROUP BY path_old
        ORDER BY opid, path_old
    ),
    /********************************************************************/
    ----------------------------- COPY LOOP ------------------------------
    LOOP_COPY AS (
            SELECT 0 AS opid, NULL AS path_new, NULL AS item_handles, json('[]') AS oplog
        UNION ALL
            SELECT ops.opid, path_new, item_handles, oplog
            FROM LOOP_COPY AS BUFFER, base_ops AS ops
            WHERE ops.opid = BUFFER.opid + 1
        UNION ALL
            SELECT
                ops.opid,
                rootpath_new || substr(path_old, length(rootpath_old) + 1) AS path_new,
                subtrees_old.item_handles,
                json_set(oplog, '$[#]', ops.opid) AS oplog
            FROM LOOP_COPY AS BUFFER, base_ops AS ops, subtrees_old
            WHERE BUFFER.path_new IS NULL
              AND ops.opid = BUFFER.opid + 1
              AND subtrees_old.opid = BUFFER.opid + 1
        UNION ALL
            SELECT
                ops.opid,
                rootpath_new || substr(path_new, length(rootpath_old) + 1) AS path_new,
                item_handles,
                json_set(oplog, '$[#]', ops.opid) AS oplog
            FROM LOOP_COPY AS BUFFER, base_ops AS ops
            WHERE ops.opid = BUFFER.opid + 1
              AND BUFFER.path_new || '/' LIKE rootpath_old || '/%'
    ),
    /********************************************************************/
    truncated AS (
        SELECT opid, NULL AS ascii_id, path_new, item_handles, oplog
        FROM LOOP_COPY
        WHERE NOT path_new IS NULL
          AND opid = (SELECT max(opid) FROM base_ops)
        ORDER BY path_new
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
    id_counts(id_counter) AS (SELECT count(*) FROM new_paths),
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
SELECT * FROM target_nodes;
```

### Code Walkthrough

The current implementation supports a *compound* copy operation, where multiple categories can be copied sequentially, making the associated code relatively complex. In practice, each "atomic" operation can be persisted by the application individually, even when multiple nodes are being moved. Code for persisting a single move/copy operation is simpler. The primary motivations for implementing the code presented here were to test the feasibility of such an approach and to practice SQL coding.

The input format and behavior of the first two CTEs **`json_ops`** and **`base_ops`** are the same as for the move operation.

#### Copy Operation Behavior

### Trigger
### Dummy data

```sql
-- Data for tree copy
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('cp_tree', json('[
                {"path_old":"/copyBAZ/bld/booze/safe00",     "path_new":"/copybbbbbb"},
                {"path_old":"/copyBAZ/bld/tcl/tests/safe00", "path_new":"/copysafe00"},
                {"path_old":"/copysafe00",                   "path_new":"/copysafe"},
                {"path_old":"/copyBAZ/dev/msys2",            "path_new":"/copyBAZ/dev/msys"},
                {"path_old":"/copyBAZ/bld/tcl/tests/preEEE", "path_new":"/copypreEEE"},
                {"path_old":"/copysafe/modules",             "path_new":"/copysafe/modu"},
                {"path_old":"/copysafe/modu/mod2",           "path_new":"/copysafe/modu/mod3"},
                {"path_old":"/copyBAZ/bld/tcl/tests/ssub00", "path_new":"/copysafe/ssub00"},
                {"path_old":"/copyBAZ/dev/msys/mingw32",     "path_new":"/copyBAZ/dev/msys/nix"},
                {"path_old":"/copysafe/ssub00/modules",      "path_new":"/copysafe/modules"},
                {"path_old":"/copyBAZ/bld/tcl/tests/manYYY", "path_new":"/copyman000"},
                {"path_old":"/copyBAZ/dev/msys/nix/etc",     "path_new":"/copyBAZ/dev/msys/nix/misc"},
                {"path_old":"/copyBAZ/bld/tcl/tests/manZZZ", "path_new":"/copyBAZ/bld/tcl/tests/man000"},
                {"path_old":"/copyBAZ/bld/tcl/tests/man000", "path_new":"/copyman000"},
                {"path_old":"/copyBAZ/bld/tcl/tests/safe11", "path_new":"/copysafe11"},
            ]'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```

---

| [**<= DELETE Operations**][DELETE] | [**Next: DELETE Operations =>**][DELETE] |
| ---------------------------------- | ---------------------------------------- |


<!-- References -->

[DELETE]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopDELETE.md
[rec-cte]: https://pchemguy.github.io/SQLite-SQL-Tutorial/patterns/rec-cte






