# SQLiteMP - Materialized Paths in SQLite with Abstract Interface

The materialized paths (MPs) model is a common approach for storing hierarchical data in relational databases. With certain general restrictions, core MP functionality can be implemented in SQL using stored procedures, providing a higher-level abstraction for applications. However, this project targets the standard SQLite library, which lacks native support for stored procedures. Consequently, the primary objective of this project is to explore alternative methods for encapsulating MP functionality using the advanced features of the standard SQLite library. The project specifically aims to rely exclusively on library-supported code (primarily SQL) while establishing an efficient code management strategy.

The SQLiteMP project demonstrates a proof-of-concept implementation of an MP data model in SQLite. Building on the concepts and code presented in my earlier [SQLite SQL Tutorial][] - which includes SQL snippets for performing common MP operations on SQLite databases - this project leverages [views][SQLite View] and [triggers][SQLite Trigger] to encapsulate MP functionality directly within the database. These features provide capabilities similar to stored procedures, while the built-in JSON functionality enables the creation of a higher-level API, minimizing the application’s direct interaction with SQL.

Although this project extends the GitHub-Pages-based SQLite SQL Tutorial, an important motivation for creating a separate repository was to simplify setup and maintenance by avoiding GitHub Pages. The standard GitHub file browser, with its automatic table-of-contents (TOC) support for Markdown-formatted files, offers a sufficiently user-friendly interface for documentation.

See [docs][] for further details.

<!-- References -->

[SQLite SQL Tutorial]: https://pchemguy.github.io/SQLite-SQL-Tutorial
[SQLite View]: https://sqlite.org/lang_createview.html
[SQLite Trigger]: https://sqlite.org/lang_createtrigger.html
[docs]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/Overview.md
