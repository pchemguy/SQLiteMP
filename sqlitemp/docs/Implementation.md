# Implementation

Each hierarchy operation may have an associated a view and trigger.


| Group  | Operation                      | `op_name`            |
| ------ | ------------------------------ | -------------------- |
| SELECT | Descendant categories          | `ls_cat_desc`        |
| SELECT | Child categories               | `ls_cat_child`       |
| SELECT | Descendant items               | `ls_item_desc`       |
| SELECT | Child items                    | `ls_item_child`      |
| SELECT | Item associations              | `ls_item_cat`        |
| SELECT | Item association counts        | `cnt_item_cat`       |
| SELECT | Child items association counts | `cnt_item_child_cat` |
| CREATE | Categories                     | new_cat              |


## SELECT

### Descendant Categories - `ls_cat_desc`

#### View

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

#### Trigger

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

#### Dummy data

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

### Child Categories - `ls_cat_child`

#### View

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

#### Trigger

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

#### Dummy data

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

### Descendant Items - `ls_item_desc`

#### View

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

#### Trigger

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

#### Dummy data

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

### Child Items - `ls_item_desc`

#### View

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

#### Trigger

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

#### Dummy data

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

### Item Associations - `ls_item_cat`

#### View

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

#### Trigger

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

#### Dummy data

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

### Item Association Counts - `cnt_item_cat`

#### View

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


#### Dummy data

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

### Child Items  Association Counts - `cnt_item_child_cat`

#### View

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

#### Dummy data

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

## CREATE

### Categories - `new_cat`

#### View

```sql
-- Unpack new categories
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
            row_number() OVER (ORDER BY path) AS opid, 
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
        SELECT *, json('{"' || replace(ltrim(path, '/'), '/', '": {"') ||
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
    path_terms AS (
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
    id_counts(id_counter) AS (SELECT count(*) FROM path_terms),
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
        SELECT bin_id AS id, iif(length(parent_path) > 0, parent_path, NULL) AS parent_path, name_new AS name
        FROM path_terms, ids USING (counter)
    )
SELECT * FROM nodes
ORDER BY lower(ifnull(parent_path, '') || '/' || name);
```

#### Dummy data

```sql
-- Data for unpacking new categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('new_cat', json_array(
                json_object('path', '/Assets/Diagrams'),
                json_object('path', '/BAZ/bld/tcl/tests/manYYY/etc'),
                json_object('path', '/Library/DllTools/CPUInfo/x32'),
                json_object('path', '/Library/DllTools/Dem - DLL/AddLib/docs'),
                json_object('path', '/Library/DllTools/Dem - DLL/AddLib/x32'),
                json_object('path', '/Library/DllTools/Dem - DLL/AddLib/x64'),
                json_object('path', '/Library/DllTools/Dem - DLL/memtools'),
                json_object('path', '/Project/SQLite/Checks'),
                json_object('path', '/Project/SQLite/Fixtures'),
                json_object('path', '/Project/SQLite/MetaSQL/Examples'),
                json_object('path', '/safe/moduleAAAAA'),
                json_object('path', '/safe/moduleBBBBB')
            ))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```


# DUMMY

---

| [**<= Previous: Storing Code in an SQLite Database**][StoredCode] | [**Next:  Storing Code in an SQLite Database =>**][StoredCode] |
| ----------------------------------------------------------------- | -------------------------------------------------------------- |


<!-- References -->

[StoredCode]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/StoredCode.md






