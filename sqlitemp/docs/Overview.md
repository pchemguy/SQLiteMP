# Data model overview

This project implements a basic hierarchical category system based on the previously discussed [design rules][MP Design Rules]. In summary, categories form a tree or forest hierarchy, with each category having at most one parent (a restriction often relaxed in modern file systems) and case-insensitive yet case-preserving names. The single-parent rule simplifies the associated SQL code compared to a more generic solution that removes this restriction.

Each category's absolute path serves as a unique identifier, ensuring that no two sibling categories can have identical names - similar to directories in a case-insensitive file system. Categories and items are stored in separate database tables, preventing name collisions between the two (unlike file systems, where directory and file names share the same namespace).

Item names are also case-insensitive yet case-preserving but do not form unique identifiers. While having multiple items with identical names assigned to the same category is generally discouraged, uniqueness of sibling item names is not enforced. Items can be assigned to multiple categories, and this many-to-many relationship is stored in a conventional database association table.

# Materialized path operations

- **CREATE**
    - **paths (categories)**: given a set of paths, create all necessary categories.
    - **items**: given a set of items, add them to the `items` table.
    - **item associations**: given a set of item associations, add information to the association table.
- **SELECT / RETRIEVE**
    - **descendant categories**: given a set of categories, retrieve the set of children or the entire subtrees.
    - **items**: given a set of categories, retrieve the set of directly associated items or all items belonging to subtrees defined by the specified categories.
    - **associated categories**: retrieve the set of categories associated with a given item.
    - **item association counts**: given a set of items, retrieve the number of categories associated with each item (whenever item information is edited, it should be immediately obvious if the item is associated with multiple categories)
- **UPDATE / MODIFY**
- **DELETE**
- **IMPORT**
- **EXPORT**

---

| [**Next: The Core Schema ->**][CoreSchema] |
| ------------------------------------------ |


<!-- References -->

[MP Design Rules]: https://pchemguy.github.io/SQLite-SQL-Tutorial/mat-paths/design-rules
[CoreSchema]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/CoreSchema.md