# Core schema

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
    "flag"          TEXT    COLLATE NOCASE,
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

<!-- References-->

[CoreSchema]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/src/sqlitemp/sql/core_schema.sql
