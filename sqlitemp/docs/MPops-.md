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
