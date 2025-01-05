## Data model overview

The project implements a basic hierarchical category system that follows previously discussed [design rules][MP Design Rules]. Briefly, categories form tree/forest hierarchy, with at most one parent (modern file systems usually relax this restrictions) and case-insensitive / case-preserving names. The single-parent rule ensures that the associated SQL code is manageable, though I have not attempted to implement a more generic solution without this restriction. The absolute path of the category forms a unique identifier (no two sibling categories may have identical names, same as in case of directories in a case-insensitive file system). Categories and items are stored in separate database tables, so their names can never collide (as opposed to file systems, where directory and file names belong to the same namespace). Item names are also case-insensitive / case-preserving, but do not form associated identifiers. While having multiple items with identical names assigned to the same category is generally discouraged, uniqueness of sibling item names is not enforced. Items may be assigned to any number of categories, and this many-to-many relation is stored in a conventional database association table.


<!-- References -->

[MP Design Rules]: https://pchemguy.github.io/SQLite-SQL-Tutorial/mat-paths/design-rules