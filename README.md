# SQLiteMP - Materialized Paths in SQLite with Abstract Interface

This project builds on the concepts and code presented in my [SQLite SQL Tutorial][] and demonstrates a proof-of-concept implementation of a materialized paths (MPs) data model for hierarchy management in SQLite. One reason for starting this separate project was to avoid the additional setup and maintenance required by GitHub Pages. I find the current feature set of the standard GitHub file browser, with its support for automatic table-of-contents (TOC) presentation, sufficient for my needs.

The primary goal of this project is to explore advanced SQLite features and determine how much MPs functionality can be implemented using only the code supported by the standard SQLite library. SQLiteMP primarily relies on SQL, but also takes advantage of the JSON subpackage included in the library. In my previous project, I presented SQL code for performing common materialized path operations on data stored in an SQLite database. However, I recently realized that SQLite’s views and triggers can be used to implement functionality often associated with stored procedures - capabilities not natively supported by standard SQLite.

With certain fairly generic restrictions, the combination of views, triggers, SQL code, and the built-in JSON package enables the implementation of typical tree manipulation operations. This approach allows all the necessary code to be stored directly within the database, offering a higher-level declarative abstraction.

<!-- References -->

[SQLite SQL Tutorial]: https://pchemguy.github.io/SQLite-SQL-Tutorial
