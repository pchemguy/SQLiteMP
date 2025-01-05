# Data model overview

This project implements a basic hierarchical category system based on the previously discussed [design rules][MP Design Rules]. In summary, categories form a tree or forest hierarchy, with each category having at most one parent (a restriction often relaxed in modern file systems) and case-insensitive yet case-preserving names. The single-parent rule simplifies the associated SQL code compared to a more generic solution that removes this restriction.

Each category's absolute path serves as a unique identifier, ensuring that no two sibling categories can have identical names - similar to directories in a case-insensitive file system. Categories and items are stored in separate database tables, preventing name collisions between the two (unlike file systems, where directory and file names share the same namespace).

Item names are also case-insensitive yet case-preserving but do not form unique identifiers. While having multiple items with identical names assigned to the same category is generally discouraged, uniqueness of sibling item names is not enforced. Items can be assigned to multiple categories, and this many-to-many relationship is stored in a conventional database association table.

[**Next: The Core Schema -\>**][CoreSchema]


|     | [**Next: The Core Schema ->**][CoreSchema] |
| --- | ------------------------------------------ |




<!-- References -->

[MP Design Rules]: https://pchemguy.github.io/SQLite-SQL-Tutorial/mat-paths/design-rules
[CoreSchema]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/CoreSchema.md