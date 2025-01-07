# Materialized path operations

- **SELECT / RETRIEVE**
  - **Descendant Categories**: Given a set of categories, retrieve the set of children or the entire subtrees.
  - **Items**: Given a set of categories, retrieve the set of directly associated items or all items belonging to subtrees defined by the specified categories.
  - **Associated Categories**: Given an item, retrieve the set of associated categories.
  - **Item Association Counts**: Given a set of items, retrieve the number of categories associated with each item (this information can be used to ensure that whenever item information is edited, it is immediately clear if the item is associated with multiple categories).

- **CREATE / IMPORT**
  - **Paths (Categories)**: Given a set of paths, create all necessary categories.
  - **Items**: Given a set of items, add them to the `items` table.
  - **Item Associations**: Given a set of item associations, add information to the association table.

- **DELETE**
  - **Delete Tree**: Given a set of categories, delete the associated subtrees and related item associations (a partial equivalent of the file system directory **delete** operation; see notes below).
  - **Remove Specific Associations**: Given a category and a set of associated items, remove items from the category (a partial equivalent of the file system symbolic link **delete** operation; see notes below).
  - **Remove All Associations**: Given a set of items, remove all related category associations.
  - **Delete Items**: Given a set of items, delete them.

- **UPDATE / MODIFY**
  - **Move Tree**: Given a category and a new path, update the category subtree and related item associations (a partial equivalent of the file system directory **rename/move** operations; see notes below).
  - **Copy Tree**: Given a category and a new path, update the category subtree and related item associations (a partial equivalent of the file system directory **copy** operation; see notes below).
  - **Move Items**: Given *source* and *destination* categories and a set of associated items, change association from *source* to *destination*.
  - **Add Items**: Given  a category and a set of items, create item associations.

- **EXPORT**
  - **Categories**
  - **Items**
  - **Item Associations**
  - **Everything**

# Limitations to the File System Analogy

Perhaps, the most common example of an abstract hierarchical data structure is represented by file system trees. Due to the ubiquity of file systems, their operations serve as an intuitive analogy for operations within a category system. While this analogy is justified - both hierarchies manage chunks of information (files or items) - it has several important limitations.

In file systems, both files and directories are identified by their names, with directories acting as file containers. Essentially, a directory is a special file that contains metadata referencing its child directories and files. As a result, directories and files share the same namespace, meaning no two sibling objects can have identical names. Additionally, a file can only be created within a specific directory. Although modern file systems provide linking features that allow a file to appear under multiple directories, a file cannot exist without at least one parent directory holding its metadata.

In contrast, categories behave more like tags. (Categories often form hierarchies, whereas tags are typically flat sets of labels.) Items can be created independently of any categories, and categories and items belong to separate database tables, ensuring their names never clash. Moreover, category and item names do not have to serve as unique identifiers; "artificial" meaningless identifiers are often used instead. Some implementations impose minimal restrictions on category names, allowing sibling categories with identical names. While valid from a database design perspective, such a convention undermines the purpose of category systems, which are created to organize information. Users rely on category names for identification, making sibling categories with identical names nonsensical.

Items, however, present a different scenario. While users typically control category names, "external" formal classifications are intentionally designed to avoid name clashes. In contrast, item titles are fixed attributes and may occasionally collide. For example, two web pages or journal articles might share identical titles. Similarly, a book, report, and thesis with the same title and classification might need to coexist within the same category system. To address potential ambiguities and assist users in managing items effectively, item lists generally include additional common metadata (e.g., type, authors, or publication date) to help distinguish identically named entries. Consequently, item names should not be restricted or relied upon as unique database identifiers. While the database engine generates "artificial" identifiers for items, it is also advisable to incorporate natural identifiers, such as ISBNs, URLs, or DOIs, where applicable (refer to the `handle` and `handle_type` fields in the `items` table).

## Move/Copy Tree

Move and copy tree operations update the `categories` table but do not directly modify items. Instead, these operations update the association table when necessary. In the current implementation, the `items_categories` table defines associations using the category path (`cat_path`), which is usually updated during move/copy operations. When a category subtree is moved without name clashes, the `name` and `parent_path` fields of all affected categories are updated, and the associated `items_categories` records are automatically adjusted thanks to the derived (generated) `path` field and cascading foreign key operations.

When name clashes occur during a move operation, the conflicting categories being moved are deleted, but their associated item relationships are updated, resulting in behavior similar to merged directories. In file systems, a directory move may overwrite destination files if names clash. In this system, however, item names cannot clash, so the only potential conflict arises when merging categories that share the same item. In such cases, the result of the move operation is removal of the clashing associations for the moved categories. The `ON CONFLICT REPLACE` resolution (used in the primary key of the `items_categories` table) ensures automatic and correct handling of these clashing associations. As noted [earlier][CoreSchema], the `REPLACE` resolution provides the expected behavior for conflicts arising from both updated association rows and newly inserted rows, whereas the `IGNORE` resolution does not handle updated records correctly.

Similarly, the copy operation creates new item associations but does not duplicate items. For clashing associations, the copy operation is effectively a no-op.

## Delete Tree

This project adopts the convention of never deleting items implicitly, even during subtree deletions. When a category subtree is deleted, only the associated item records in the `items_categories` table are removed. Items themselves are deleted only when explicitly specified in the "delete items" operation.


---

| [**<= Previous: The Core Schema**][CoreSchema] | [**Next:  Storing Code in an SQLite Database =>**][StoredCode] |
| ---------------------------------------------- | -------------------------------------------------------------- |


<!-- References -->

[CoreSchema]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/CoreSchema.md
[StoredCode]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/StoredCode.md