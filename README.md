# SQLiteMP - Materialized Paths in SQLite with Abstract Interface

**SQLiteMP** is a proof-of-concept SQL implementation of the materialized paths (MPs) tree model, embedded within an SQLite database.

## **Features**

- **Hierarchical Category Model**: Manages category systems with single-parent tree categories.
- **Flexible Item Association**: Associates items with multiple categories, enabling more versatile data organization.
- **Common Materialized Paths Operations**: Supports creation, deletion, movement, copying, importing, and exporting.
- **JSON-Based API**: Offers a minimalistic SQL interface for seamless interaction.
- **Encapsulated SQL Logic**: Improves modularity and reduces code coupling by embedding SQL logic within database views and triggers.
- **Simplified SQL Management**: Reduces the application's need to handle complex SQL code directly.
- **Structured and Maintainable Code**: Leverages ordinary and recursive common table expressions (CTEs) for clear and maintainable code.
- **Pseudo-Parameterized Views and Triggers**: Implements parameterization through auxiliary buffer tables for added flexibility.
- **Recursive Triggers for DRY Code**: Facilitates development of complex SQL logic (not yet implemented).
- **Standard SQLite Compatibility**: Fully implemented using the standard SQLite library.

---

## **Codebase**

The project primarily consists of organized SQL code. Currently, a directory structure has been created for a Python project, as Python is a suitable platform for setting up tests and a demo project. However, no actual Python development has been implemented yet.

The SQL code is embedded in the documentation and is also included in modules located under `sqlitemp/src/sqlitemp/sql`. These modules contain the same code as documented and can be directly imported into an SQLite database. This directory also includes additional JSON and SQL modules with dummy data for manual testing.

## **Testing**

While I recognize the importance of a proper automated testing setup, only manual testing has been performed so far during the main code development process.

## **Documentation**

The project documentation is located in the `sqlitemp/docs` directory, with the entry file being `Overview.md`. These files can be viewed using GitHub’s file explorer by [opening][docs] them in a browser.

Most documents are structured using Markdown headings. When a file is opened in GitHub’s file explorer, the command bar at the top displays a TOC (Table of Contents) icon as the rightmost icon. This `README.md` file includes headings, so the TOC icon should appear in the command bar. By default, the TOC sidebar is hidden, but clicking the icon opens it, allowing for convenient navigation. Individual documents can be accessed through the file explorer sidebar on the left or by using the Previous/Next links at the bottom of each document.

---

The materialized paths (MPs) model is a common approach for storing hierarchical data in relational databases. With certain general restrictions, core MP functionality can be implemented in SQL using stored procedures, providing a higher-level abstraction for applications. However, this project targets the standard SQLite library, which lacks native support for stored procedures. Consequently, the primary objective of this project is to explore alternative methods for encapsulating MP functionality using the advanced features of the standard SQLite library. The project specifically aims to rely exclusively on library-supported code (primarily SQL) while establishing an efficient code management strategy.

The SQLiteMP project demonstrates a proof-of-concept implementation of an MP data model in SQLite. Building on the concepts and code presented in my earlier [SQLite SQL Tutorial][] - which includes SQL snippets for performing common MP operations on SQLite databases - this project leverages [views][SQLite View] and [triggers][SQLite Trigger] to encapsulate MP functionality directly within the database. These features provide capabilities similar to stored procedures, while the built-in JSON functionality enables the creation of a higher-level API, minimizing the application’s direct interaction with SQL.

Although this project extends the GitHub-Pages-based SQLite SQL Tutorial, an important motivation for creating a separate repository was to simplify setup and maintenance by avoiding GitHub Pages. The standard GitHub file browser, with its automatic table-of-contents (TOC) support for Markdown-formatted files, offers a sufficiently user-friendly interface for documentation.

See [docs][] for further details.

<!-- References -->

[SQLite SQL Tutorial]: https://pchemguy.github.io/SQLite-SQL-Tutorial
[SQLite View]: https://sqlite.org/lang_createview.html
[SQLite Trigger]: https://sqlite.org/lang_createtrigger.html
[docs]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/Overview.md
