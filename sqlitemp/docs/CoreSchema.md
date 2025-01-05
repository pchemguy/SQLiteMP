# Core schema

## Categories table

| <center>Field</center> | <center>Attributes</center> | <center>Description</center>                                                                                                                                                                                                                                                                                               |
| ---------------------- | :-------------------------: | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`id`**               |    **INTEGER**<br>**PK**    | 64-bit integer, restricted (but not enforced) to a subset, where each byte is an ASCII code of an alphanumeric character.                                                                                                                                                                                                  |
| **`name`**             |          **TEXT**           | Case-insensitive category name, prohibited characters include colon, comma, double quote, slashes, TAB, CR, LF.                                                                                                                                                                                                            |
| **`parent_path`**      |          **TEXT**           | Forward-slash-sepated path not including the name of the category. `parent_path` includes leading, but not trailing '/' and is set to NULL for top-level categories. `parent_path` references the generated `path` field with propagation on both update and delete operations, constructed from `parent_path` and `name`. |
| **`ascii_id`**         |  **TEXT**<br>**GENERATED**  | ASCII representation of the `id` field. To further reduce the probability of collision, this field is declared as case-sensitive.                                                                                                                                                                                          |
| **`path`**             |  **TEXT**<br>**GENERATED**  | Constructed from `parent_path` and `name`.                                                                                                                                                                                                                                                                                 |

## Items table

| <center>Field</center> | <center>Attributes</center> | <center>Description</center>                                                                                                      |
| ---------------------- | :-------------------------: | --------------------------------------------------------------------------------------------------------------------------------- |
| **`id`**               |    **INTEGER**<br>**PK**    | 64-bit integer, restricted (but not enforced) to a subset, where each byte is an ASCII code of an alphanumeric character.         |
| **`name`**             |          **TEXT**           | Case-insensitive item name, prohibited characters include colon, comma, double quote, slashes, TAB, CR, LF.                       |
| **`handle_type`**      |          **TEXT**           | Type of primary item identifier, such as, DOI, ISBN, URL, etc.                                                                    |
| **`handle`**           |   **TEXT**<br>**UNIQUE**    | Case-insensitive primary item identifier, such as, DOI, ISBN, URL, etc.                                                           |
| **`ascii_id`**         |  **TEXT**<br>**GENERATED**  | ASCII representation of the `id` field. To further reduce the probability of collision, this field is declared as case-sensitive. |

## Association table

| <center>Field</center> | <center>Attributes</center> | <center>Description</center> |
| ---------------------- | :-------------------------: | ---------------------------- |
| **`cat_path`**         |          **TEXT**           | Category path.               |
| **`item_handle`**      |          **TEXT**           | Item handle.                 |

The minimalistic `items_categories` table includes two fields forming the table primary key. The PK is set to REPLACE rows on conflict, which is a sensible strategy simplifying the SQL code for MP operations. Conflicts may occur, for example, during bulk UPDATE or INSERT operations. For the INSERT operation, the IGNORE resolution works equally well. However, in case of the UPDATE operation, the IGNORE resolution would incorrectly keep the old association in the table.

<details>  
<summary><b>Core schema</b></summary>  

```sql
DROP TABLE IF EXISTS "categories";
CREATE TABLE "categories" (
                            -- Unique ID for each category, 64-bit integer
    "id"            INTEGER PRIMARY KEY,
                            -- Name of the category, case-insensitive
    "name"          TEXT    NOT NULL COLLATE NOCASE
                            CHECK (
                                NOT instr(name, ':') AND
                                NOT instr(name, ',') AND
                                NOT instr(name, '"') AND
                                NOT instr(name, '/') AND
                                NOT instr(name, char(0x5C)) AND
                                NOT instr(name, char(0x0A)) AND
                                NOT instr(name, char(0x0D)) AND
                                NOT instr(name, char(0x09)) AND
                                length(name) > 0
                            ),
                            -- Parent category path, nullable for top-level categoriess
    "parent_path"   TEXT    COLLATE NOCASE
                                REFERENCES "categories"("path") ON DELETE CASCADE ON UPDATE CASCADE,
                            -- Used for housekeeping purposes
    "ascii_id"      TEXT    NOT NULL UNIQUE COLLATE BINARY
                            GENERATED ALWAYS AS (
                                char(
                                    (abs(id) >> 8 * 7) & 255,
                                    (abs(id) >> 8 * 6) & 255,
                                    (abs(id) >> 8 * 5) & 255,
                                    (abs(id) >> 8 * 4) & 255,
                                    (abs(id) >> 8 * 3) & 255,
                                    (abs(id) >> 8 * 2) & 255,
                                    (abs(id) >> 8 * 1) & 255,
                                    (abs(id) >> 8 * 0) & 255
                                )
                            ),
                            -- Materialized path, case-insensitive
    "path"          TEXT    NOT NULL UNIQUE COLLATE NOCASE
                            GENERATED ALWAYS AS (ifnull("parent_path", '') || '/' || "name"),
                            -- Ensure unique category names under the same parent
    UNIQUE("name", "parent_path")
);

-- Index for quick lookup by parent_path
CREATE INDEX "idx_categories_parent_path" ON "categories" ("parent_path");


DROP TABLE IF EXISTS "items";
CREATE TABLE "items" (
                            -- Unique ID for each item, 64-bit integer
    "id"            INTEGER PRIMARY KEY,
                            -- Name of the item, case-insensitive
    "name"          TEXT    NOT NULL COLLATE NOCASE
                            CHECK (
                                NOT instr(name, ':') AND
                                NOT instr(name, ',') AND
                                NOT instr(name, '"') AND
                                NOT instr(name, '/') AND
                                NOT instr(name, char(0x5C)) AND
                                NOT instr(name, char(0x0A)) AND
                                NOT instr(name, char(0x0D)) AND
                                NOT instr(name, char(0x09)) AND
                                length(name) > 0
                            ),
    "handle_type"   TEXT    NOT NULL COLLATE NOCASE,
    "handle"        TEXT    NOT NULL COLLATE NOCASE UNIQUE,
                            -- Textual representation of the ID
    "ascii_id"      TEXT    NOT NULL UNIQUE COLLATE BINARY
                            GENERATED ALWAYS AS (
                                char(
                                    (abs(id) >> 8 * 7) & 255,
                                    (abs(id) >> 8 * 6) & 255,
                                    (abs(id) >> 8 * 5) & 255,
                                    (abs(id) >> 8 * 4) & 255,
                                    (abs(id) >> 8 * 3) & 255,
                                    (abs(id) >> 8 * 2) & 255,
                                    (abs(id) >> 8 * 1) & 255,
                                    (abs(id) >> 8 * 0) & 255
                                )
                            )
);


DROP TABLE IF EXISTS "items_categories";
CREATE TABLE "items_categories" (
    "cat_path"      TEXT COLLATE NOCASE REFERENCES categories(path) ON DELETE CASCADE ON UPDATE CASCADE,
    "item_handle"   TEXT COLLATE NOCASE REFERENCES items(handle) ON DELETE CASCADE ON UPDATE CASCADE,
    PRIMARY KEY(cat_path, item_handle) ON CONFLICT REPLACE
);

CREATE INDEX idx_items_categories_item_handle ON items_categories(item_handle);
```

</details>  

---  

| [**<= Previous: Overview**][Overview] | [**Next: The Core Schema =>**][CoreSchema] |
| ------------------------------------- | ------------------------------------------ |


<!-- References-->

[CoreSchema]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/src/sqlitemp/sql/core_schema.sql
[Overview]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/Overview.md
