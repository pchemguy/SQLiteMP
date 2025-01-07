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
| CREATE | Categories                     | `new_cat`            |
| CREATE | Items                          | `new_item`           |
| CREATE | Item associations              | `new_item_cat`       |
| CREATE | *Import (everything)*          | *not implemented*    |
| DELETE | Categories                     | `del_cat`            |
| DELETE | Item associations              | `del_item_cat`       |
| DELETE | Item associations reset        | `reset_item_cat`     |

---
---

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


---
---

## CREATE

### Categories - `new_cat`

#### View

```sql
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
```

#### Code Walkthrough

**`json_ops`**, as before, retrieves the latest record from the `hierarchy_ops` table containing a list of slash-separated category paths to be created, for example:

```json
[
    {"path": "/Assets/Diagrams"},
    {"path": "/BAZ/bld/tcl"}
]
```

**`base_ops`** unpacks the JSON input into a table:

| opid | <center>path</center> |
| :--: | --------------------- |
|  1   | /Assets/Diagrams      |
|  2   | /BAZ/bld/tcl          |

**`levels`** and **`json_objs`** generate a nested JSON object for each path:

| <center>opid</center> | <center>path</center> | <center>depth</center> | <center>json_obj</center>    |
| :-------------------: | --------------------- | :--------------------: | ---------------------------- |
|           1           | /Assets/Diagrams      |           2            | `{"Assets":{"Diagrams":""}}` |
|           2           | /BAZ/bld/tcl          |           3            | `{"BAZ":{"bld":{"tcl":""}}}` |

**`ancestors`** uses the `json_tree` to walk the JSON tree and generate a complete list of all categories, in this case:

| <center>opid</center> | <center>path_new</center> | <center>name_new</center> |
| :-------------------: | ------------------------- | ------------------------- |
|           1           | /Assets                   | Assets                    |
|           1           | /Assets/Diagrams          | Diagrams                  |
|           2           | /BAZ                      | BAZ                       |
|           2           | /BAZ/bld                  | bld                       |
|           2           | /BAZ/bld/tcl              | tcl                       |

**`filtered_terms`** discards any rows from this table that correspond to already existing categories.

The ASCII ID generator section comes with minor adjustments from [previously published][ASCII ID generator] snippet. To some extent, this code was more like an exercise, because SQLite can be compiled with an extension that generates UUIDs. Still, this code should work with standard precompiled or preinstalled binaries without the need for customizing the library or loading extensions.

**`nodes`** generates the final list of new categories ready to be processed, for example by the associated trigger code.

#### Trigger

```sql
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
```

#### Dummy data

```sql
-- Data for preparing the list of new categories
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


### Items - `new_item`

#### View

```sql
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
```

The code of **`new_item`** view is mostly similar to the **`new_cat`** view, except for the section processing hierarchal entities.

#### Trigger

```sql
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
```

#### Dummy data

```sql
-- Data for preparing the list of new items
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('new_item', json('
                [
                    {
                        "handle": "e102a4954b60ebf024498b87b033c961A",
                        "handle_type": "md5",
                        "name": "MemtoolsLib.sh"
                    },
                    {
                        "handle": "fb351622f997ec7686e1cd0079dbccaA",
                        "handle_type": "md5",
                        "name": "ColumnsEx.doccls"
                    },
                    {
                        "handle": "df5965bd43b2dd9b3c78428330136ec0A",
                        "handle_type": "md5",
                        "name": "addclient.c"
                    },
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```


### Item Associations - `new_item_cat`

#### View

```sql
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
    base_ops AS (
        SELECT
            "key" + 1 AS opid,
            json_extract(value, '$.op') AS op,
            json_extract(value, '$.cat_path') AS cat_path,
            json_extract(value, '$.item_handle') AS item_handle
        FROM json_ops AS jo, json_each(jo.json_op) AS terms
    ),
    filtered_terms AS (
        SELECT base_ops.cat_path, base_ops.item_handle
        FROM base_ops
        LEFT JOIN items_categories USING (cat_path, item_handle)
        WHERE items_categories.item_handle IS NULL
    )
SELECT cat_path, item_handle FROM filtered_terms;
```

#### Trigger

```sql
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
```

#### Dummy data

```sql
-- Data for preparing the list of new item associations
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('new_item_cat', json('
                [
                    {
                        "cat_path": "/Assets",
                        "item_handle": "f1281500266a0c49737643580e91f188"
                    },
                    {
                        "cat_path": "/Assets",
                        "item_handle": "ec5b638f0f2e1d3e70a404008b766145"
                    },
                    {
                        "cat_path": "/Assets",
                        "item_handle": "e8e18009c40bf038603f86b4d7d8c712"
                    },
                    {
                        "cat_path": "/Assets",
                        "item_handle": "fe207105e0f7ad3d6861742bc5030f79"
                    },
                    {
                        "cat_path": "/Assets/Diagrams",
                        "item_handle": "ea656b9ffb993e6fd6d115af0d335cd2"
                    },
                    {
                        "cat_path": "/Assets/Diagrams",
                        "item_handle": "e8ec0b1284b6bfba26703fe87874e185"
                    },
                    {
                        "cat_path": "/Assets/Diagrams",
                        "item_handle": "e829a9ebe06e47ec764c421ba8550aff"
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/AddLib",
                        "item_handle": "df5965bd43b2dd9b3c78428330136ec00"
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/AddLib/docs",
                        "item_handle": "f44c82c9953acda15a1b2ff73a0d4ca00"
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/AddLib/docs",
                        "item_handle": "fdc86b4a4b2332606fc5cef72969b10a0"
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/memtools",
                        "item_handle": "e102a4954b60ebf024498b87b033c9610"
                    },
                    {
                        "cat_path": "/Project/SQLite/Checks",
                        "item_handle": "d2d3a850f6495f38ee6961d4eee2c5ee"
                    },
                    {
                        "cat_path": "/Project/SQLite/Fixtures",
                        "item_handle": "d6b43bf13d30207b5147d8ecaa5f230c"
                    },
                    {
                        "cat_path": "/Project/SQLite/Fixtures",
                        "item_handle": "ff05b9ccc2185c93d1acf00bb3dbdf73"
                    },
                    {
                        "cat_path": "/Project/SQLite/MetaSQL/Examples",
                        "item_handle": "e84a16319e2a7a2f001996ea610b91d2"
                    },
                    {
                        "cat_path": "/Project/SQLite/MetaSQL/Examples",
                        "item_handle": "fb351622f997ec7686e1cd0079dbccab"
                    },
                    {
                        "cat_path": "/Project/SQLite/MetaSQL/Examples",
                        "item_handle": "d10a1b89819187b75515de6c3400c417"
                    },
                    {
                        "cat_path": "/BAZ/bld",
                        "item_handle": "f1281500266a0c49737643580e91f188"
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests",
                        "item_handle": "df5965bd43b2dd9b3c78428330136ec00"
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests",
                        "item_handle": "e102a4954b60ebf024498b87b033c9610"
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests/manYYY",
                        "item_handle": "f44c82c9953acda15a1b2ff73a0d4ca01"
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests/manYYY/etc",
                        "item_handle": "fdc86b4a4b2332606fc5cef72969b10a1"
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests",
                        "item_handle": "e829a9ebe06e47ec764c421ba8550aff"
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests/manYYY",
                        "item_handle": "ec4d23b69f463d8314adfec69748354e"
                    }
                ]
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
```



### Import

A JSON containing a complete set of records (`items`, `categories`, `items_categories`) may be imported via individual handlers by taking advantage of recursive triggers. This idea is presently not implemented however. 

## DELETE

### Categories - `del_cat`

#### View

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

#### Trigger

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

Cascading foreign keys make sure that category subtrees and related item association are deleted. Items remain otherwise unaffected.

#### Dummy data

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




### Item Associations - `del_item_cat`

#### View

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

#### Trigger

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

#### Dummy data

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







### Reset Item Associations - `reset_item_cat`

#### View

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

#### Trigger

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

#### Dummy data

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







# DUMMY

---

| [**<= Previous: Storing Code in an SQLite Database**][StoredCode] | [**Next:  Storing Code in an SQLite Database =>**][StoredCode] |
| ----------------------------------------------------------------- | -------------------------------------------------------------- |


<!-- References -->

[StoredCode]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/StoredCode.md
[ASCII ID generator]: https://pchemguy.github.io/SQLite-SQL-Tutorial/patterns/ascii-id





