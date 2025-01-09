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

The **`LOOP_MOVE`** CTE is recursive and represents the most complex component of this implementation (refer to this [RCTE tutorial][rec-cte]). The non-recursive (initialization) `SELECT` populates the recursive buffer/queue with all rows from **`subtrees_old`**. The recursive `SELECT` then sequentially applies each requested move operation to the prepared set of affected nodes. Intermediate states of the category tree and item associations are disregarded, as only the final new path `path_moved` for each category is necessary to correctly update the target database tables.

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
```

### **Code Walkthrough**

The current implementation supports a *compound* copy operation, where multiple categories can be copied sequentially. This adds complexity to the associated code. In practice, each "atomic" operation can be handled individually by the application, even when multiple nodes are copied. Implementing a single move/copy operation is simpler. The primary objectives of this implementation were to test the feasibility of such an approach and to practice advanced SQL coding techniques.

The input format and behavior of the first two CTEs, **`json_ops`** and **`base_ops`**, remain the same as for the move operation.

---

#### **Copy Operation Behavior**

The copy operation differs from the move operation in that it never deletes categories. If the destination path does not exist, new categories are created; otherwise, no changes are made. For newly created categories, item associations are duplicated from their source categories.

`subtrees_old` adds the `src_path` field (compared to the move operation). This field labels each source category and is passed on to the generated copies in the **`LOOP_COPY`** CTE. It is essential for tracking and processing item association information during the copy process.

---

#### **`LOOP_COPY`**

The **`LOOP_COPY`** recursive CTE is more elaborate than the move loop. It pulls rows from the `base_ops` and `subtrees_old` CTEs, processing them sequentially. The `base_ops` and `subtrees_old` outputs may look like this:

**`base_ops`**

| opid | rootpath_old                 | rootpath_new                 |
|:----:|------------------------------|------------------------------|
|  1   | /copyA                       | /copyB                       |
|  2   | /copyBAZ/bld/tcl/tests/safe00| /copysafe00                  |
|  3   | /copysafe00                  | /copysafe                    |
|  4   | /copyBAZ/dev/msys2           | /copyBAZ/dev/msys            |

**`subtrees_old`**

| opid | path_old                                     |
| :--: | -------------------------------------------- |
|  1   | /copyA                                       |
|  2   | /copyBAZ/bld/tcl/tests/safe00/ssub00         |
|  2   | /copyBAZ/bld/tcl/tests/safe00/ssub00/modules |
|  4   | /copyBAZ/dev/msys2                           |
|  4   | /copyBAZ/dev/msys2/clang32                   |

These tables show, for example, that operation #1 processes `/copyA => /copyB` (the row in the `base_ops` table where `opid` = 1), and the only existing category matching the source path for operation #1 is `/copyA` (the rows in the `subtrees_old` table where `opid` = 1).

---

Think of `LOOP_COPY` as a "for" loop, where the iteration variable is `opid`, defined on the recursive buffer table. At initialization, the non-recursive `SELECT` inserts a single dummy row into the recursive buffer table:

```sql
SELECT 0 AS opid, NULL AS path_new, NULL AS src_path, json('[]') AS oplog
```

The loop body has three `SELECT` blocks:

1. **Carry Forward Rows**: Copies all rows from the previous iteration into the buffer table with `opid` incremented. This step ensures that categories created in earlier steps are available for subsequent operations.
2. **Load Source Categories**: Selects categories matching the source path of the current operation (`path_old`). The query includes a filter to avoid redundant joins:
   ```sql
   WHERE lc.path_new IS NULL
   ```
   This filter ensures that only the initialization row is used to extract `opid`, improving performance.
3. **Apply Copy Operation**: Processes the copy operation for all rows produced in the previous cycle, generating new paths.

Recursion terminates when the `opid` exceeds the maximum in **`base_ops.opid`**.

---

#### Postprocessing and Collision Handling

- **`truncated_src_path`**: Extracts results from the final `LOOP_COPY` iteration, discarding the dummy row.
- **`truncated`**: Retrieves and formats item associations for each row as JSON arrays.
- **`subtrees_path`**: Handles collisions by grouping rows with the same destination path (`path_new`) and merging item association lists into valid JSON arrays.
- **`collisions`**: Labels rows where `path_new` matches existing categories.
- **`subtrees_names`**: Extracts category names from `path_new`.
- **`new_paths`**: Generates `prefix_new` (the `parent_path` field).
- **`target_nodes`**: Produces the final output by joining data with the ASCII ID generator prepared `ids` CTE output.

---

#### Trigger Code

The trigger code follows a two-step sequence:

1. **Create New Categories**: Creates categories without name collisions first (nothing is to be done for colliding targets).
2. **Update Association Table**: Adds item association records for the newly created categories. The `ON CONFLICT REPLACE` clause ensures any conflicts are resolved automatically, eliminating the need to filter out existing records explicitly.

### Trigger

```sql
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
```

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

| [**<= DELETE Operations**][DELETE] |
| ---------------------------------- |


<!-- References -->

[DELETE]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopDELETE.md
[rec-cte]: https://pchemguy.github.io/SQLite-SQL-Tutorial/patterns/rec-cte






