# SQLiteMP - Materialized Paths in SQLite with Abstract Interface

The materialized paths (MPs) is one of the common approaches to modeling hierarchical data for storing in relational databases. With certain fairly generic restrictions, the core MPs functionality may be implemented in SQL using stored procedures, providing a higher-level abstraction to applications. The SQLiteMP project, however, targets the standard SQLite library, which does not provide native support for stored procedures. The primary goal of this project is, therefore, to explore alternative means for encapsulation of MPs functionality using advanced features of the standard SQLite library. The objectives are to rely only on the code supported by the library, that is SQL, and devise a convenient code management strategy.

The SQLiteMP project demonstrates a proof-of-concept implementation of an MPs data model in SQLite. This project builds on the concepts and code presented in my earlier [SQLite SQL Tutorial][] project, which includes SQL code snippets for performing common MPs operations on data stored in an SQLite database. By taking advantage of [views][SQLite View] and [triggers][SQLite Trigger], this code can, in fact, be stored directly within the database, providing functionality similar to stored procedures. Further, the built-in JSON functionality makes it possible to reduce application exposure to SQL, providing a higher-level API. While the current project extends GitHub-Pages-based SQLite SQL Tutorial, one reason for starting a separate repository was to avoid the additional setup and maintenance required by GitHub Pages. I find the current feature set of the standard GitHub file browser, with its support for automatic table-of-contents (TOC) presentation, sufficient for my needs.


<!-- References -->

[SQLite SQL Tutorial]: https://pchemguy.github.io/SQLite-SQL-Tutorial
[SQLite View]: https://sqlite.org/lang_createview.html
[SQLite Trigger]: https://sqlite.org/lang_createtrigger.html