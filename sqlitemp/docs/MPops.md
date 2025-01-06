# Materialized path operations

- **CREATE / IMPORT**
    - **paths (categories)**: Given a set of paths, create all necessary categories.
    - **items**: Given a set of items, add them to the `items` table.
    - **item associations**: Given a set of item associations, add information to the association table.
- **SELECT / RETRIEVE**
    - **descendant categories**: Given a set of categories, retrieve the set of children or the entire subtrees.
    - **items**: Given a set of categories, retrieve the set of directly associated items or all items belonging to subtrees defined by the specified categories.
    - **associated categories**: Given an item, retrieve the set of associated categories.
    - **item association counts**: Given a set of items, retrieve the number of categories associated with each item (whenever item information is edited, it should be immediately obvious if the item is associated with multiple categories).
- **UPDATE / MODIFY**
    - **move tree**: Given a category and a new path, update the category subtree and related item associations (a partial equivalent of the file system directory **rename/move** operations, see notes below).
    - **copy tree**: Given a category and a new path, update the category subtree and related item associations (a partial equivalent equivalent of the file system directory **copy** operation, see notes below).
- **DELETE**
    - **delete tree**: Given a set of categories, delete the associated subtrees and related item associations (a partial equivalent of the file system directory **delete** operation, see notes below).
    - **remove specific associations**: Given a category and a set of associated items, remove items from the category (a partial equivalent of the file system file symbolic link **delete** operation, see notes below).
    - **remove all associations**: Given a set of items, remove all associated categories.
    - **delete items**: Given a a set of items, delete them (a partial equivalent of the file system file **delete** operation, see notes below).
- **EXPORT**
    - **categories**
    - **items**
    - **item association**
    - **everything**

# Limitations to the file system analogy

Perhaps, the most common abstract hierarchical data structure example is represented by file system trees. Because of the ubiquity of file systems, file system operations serve as convenient intuitive analogy to operations over category system. While such an analogy is justified, because in both cases the role of the hierarchy is to manage chunks of information (files or items), this analogy has certain important limitations. 

In file systems, both files and directories are identified by their names, and directories act as file containers. Essentially, a directory is a special file that only contains metadata, referencing its child directories and files. An important consequence of this design is that directories and files share the same namespace, and no two sibling objects can have identical names. Another consequence is that a file can only be created within a particular directory. While modern file systems provide the linking features, enabling placement of the same file under multiple directories, a file cannot exist without at least one parent directory, which holds file metadata information.

Categories act more like tags (in fact both concepts are used with a slightly different meaning: categories often form a hierarchy, whereas tags are usually flat sets of labels), as items can be created irrespective of any categories. Categories and items belong so separate database tables, so their names can never clash. Further, names do not have to be used as identifiers, as "artificial" meaningless identifiers can be and are often used instead. In fact, some category system implementations do impose little, if any, name restrictions, making it possible to have sibling categories with identical names. From the database design standpoint, unrestricted category names is perfectly valid convention. However, category systems are created to organize information, and users of such systems identify categories by their names. For these reason, allowing sibling categories with identical names is a complete nonsense.

Items are somewhat different. The user is usually in control of category names. When "external" formal classifications are used, it is fairly obvious that those classifications can never have clashing names. Item title, on the other hand, is often one of the fixed item attribute. Items are also created and named independently. For example, two web pages or two journal articles may have identical names. A book, report, and thesis with identical names and, possibly, classifications, may need to be added to the same category system. At the same time, item lists usually display not only names, but also some additional common metadata (such as type or authors), which help distinguish between identically named items. For this reason, item names should not be restricted or used as unique database identifiers. While the database engine can and does generate "artificial" meaningless identifiers, it is a good idea to still use natural item identifiers, such as ISBNs, URLs, DOIs, etc. (see the `handle` and `handle_type` fields of the `items` table).

## Move/copy tree

Move/copy tree operations update the `categories` table, but never touch items directly. Instead, these operations, when necessary, update the association table. Because present implementation of the `items_categories` association table uses category path (`cat_path`) for defining associations, the association records are always updated during move/copy tree operations. When a category subtree is moved and no name clashing occurs, `name` and `parent_path` of all affected categories are updated, and the associated `items_categories` records are updated automatically thanks to the generated field `path` and cascaded foreign key operations. When some category names clash as a result of the move operation, the conflicting categories being moved are deleted, but related item associations are updated producing a result similar to merged directories. A directory move operation may overwrite destination files in case of clashing file names. Because item names cannot clash, the only potential collision is when the categories being merged are assigned the same item. In such a case, the effect of the move operation for clashing associations is removal of the association records for categories being moved. `ON CONFLICT REPLACE` resolution (the primary key of the `items_categories` tables) enables automatic correct processing of clashing association. Similarly, the copy operation creates new item associations, but not new items. For clashing association, the copy operation is simply a no-op.

# Delete tree
