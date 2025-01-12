# Tutorial

## Database Preparation

This practical exercise involves the following steps:

1. **Obtain Tutorial SQL Files**  
   Download the required SQL files from the repository's [sql][] directory. This directory contains several `.sql` files and a `tutorial.zip` archive, which includes the same SQL files. Note that these files were created from the SQL code embedded in the repository's documentation.

2. **Create a New Database**  
   Start by creating a new blank SQLite database.

3. **Import the Schema Module**  
   Import the schema module `core_schema.sql` into the database.
   
4. **Import the Dummy Data Module**  
   Import the dummy data module `core_schema_dummy_data.sql`.
   
5. **Import Operation Modules**  
   Import the following modules in any order: `op_select.sql`, `op_create.sql`, `op_modify.sql`, `op_delete.sql`, and `op_export.sql`.  
   The remaining files - `dummy_select.sql`, `dummy_create.sql`, `dummy_modify.sql`, `dummy_delete.sql`, and `dummy_export.sql` - contain demo data corresponding to the "Dummy Data" sections of their respective documentation pages.  
   After completing this step, the database should contain:   
       - **4 non-system tables**  
       - **2 indexes**  
       - **24 views**  
       - **22 triggers**  
   Note: Most views will initially be empty, except for `exp_*` views, `ls_cat_empty`, and `ls_item_unfiled`.

6. **Import `dummy_select.sql`**  
   After importing this module, all `ls_*` and `cnt_*` views should display appropriate data. Additionally, the `hierarchy_ops.payload` field for `ls_*` operations should contain JSON-packed data.
   
7. **Import `dummy_export.sql`**  
   Importing this module updates the `exp_cat` view and populates the corresponding row in the `hierarchy_ops.payload` field.
   
8. **Import `dummy_create.sql`**  
   This module adds three rows to the `hierarchy_ops` table with the `payload` field set to `NULL`. However, the associated `new_*` views will not return any rows unless the associated `new_*` triggers are deleted before importing the module.
   
9. **Import `dummy_modify.sql` and `dummy_delete.sql`**  
   These modules add several rows to the `hierarchy_ops` table with the `payload` field set to `NULL`. The associated views will not provide useful information, so you should examine the affected data tables directly.

## Debugging and Troubleshooting SQL



---

| [**<= EXPORT Operations**][EXPORT] |
| ---------------------------------- |

<!-- References -->

[EXPORT]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopEXPORT.md
[sql]: https://github.com/pchemguy/SQLiteMP/tree/main/sqlitemp/src/sqlitemp/sql
