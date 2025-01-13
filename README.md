# Managing Hierarchical Category Systems in SQLite

**SQLiteMP** is a proof-of-concept SQL implementation of the materialized paths (MPs) tree model, embedded within an SQLite database.

## **Features**

- **[Hierarchical Category Model][CoreSchema]**: Manages category systems with single-parent tree categories.
- **Flexible Item Association**: Associates items with multiple categories, enabling more versatile data organization.
- **Referential Integrity**: Implements foreign keys using a generated column to ensure data consistency.
- **Cascading Foreign Keys**: Leverages cascading rules to streamline hierarchy management and ensure referential integrity.
- **Conflict Resolution Clause**: Simplifies operations involving complex SQL logic (e.g., tree move or copy)
- **[Common Materialized Paths Operations][MPops]**: Supports [creation][CREATE], [deletion][DELETE], [movement, copying][MODIFY], [importing][CREATE], and [exporting][EXPORT].
- **JSON-Based API**: Offers a minimalistic SQL interface for seamless interaction.
- **[Encapsulated SQL Logic][StoredCode]**: Improves modularity and reduces code coupling by embedding SQL logic within database views and triggers.
- **Simplified SQL Management**: Reduces the application's need to handle complex SQL code directly.
- **Structured and Maintainable Code**: Leverages ordinary and recursive common table expressions (CTEs) for clear and maintainable code.
- **[Pseudo-Parameterized Views and Triggers][ParamViewTrigger]**: Implements parameterization through auxiliary buffer tables for added flexibility.
- **Recursive Triggers for DRY Code**: Facilitates development of complex SQL logic (not yet implemented).
- **Standard SQLite Compatibility**: Ensures portability and ease of use by relying on preinstalled binaries.
- **[Step-by-Step Tutorial][]**: Offers a practical guide to setting up a demo database using the provided schema and dummy data modules.
- **[Debugging vies and triggers][Debug]**: Suggests approaches for robust semi-automated troubleshooting.

---

## **Codebase**

The project directory is structured as a Python project, with plans to use Python for testing and demo purposes in the future. Currently, the project primarily consists of organized SQL code, which is embedded in the documentation and included in modules located under [sqlitemp/src/sqlitemp/sql][SQL]. These SQL modules replicate the documented code and can be directly imported into an SQLite database. Additionally, the directory contains JSON and SQL modules with dummy data for manual testing. While I recognize the importance of setting up proper automated testing, only limited manual testing has been conducted so far.

## **Documentation**

The project documentation is located in the [sqlitemp/docs][docs] directory, with the entry file being [Overview.md][Overview]. These files can be viewed using GitHub’s file explorer by [opening][Overview] them in a browser. Most documents are organized using Markdown headings. When such a file is opened in GitHub’s file explorer, the command bar at the top displays a TOC (Table of Contents) icon as the rightmost icon. This [README.md][] file includes Markdown headings, so the TOC icon should appear in the command bar. By default, the TOC sidebar is hidden, but clicking the icon reveals it, enabling convenient navigation. Individual documents can also be accessed through the file explorer sidebar on the left or by following the Previous/Next links at the bottom of each document.

---

The [materialized paths (MPs)][MP] model is a common approach for storing hierarchical data in relational databases. With certain general restrictions, core MP functionality can be implemented in SQL using stored procedures, providing a higher-level abstraction for applications. However, this project targets the standard SQLite library, which lacks native support for stored procedures. Consequently, the primary objective of this project is to explore alternative methods for encapsulating MP functionality using the advanced features of the standard SQLite library. The project specifically aims to rely exclusively on library-supported code (primarily SQL) while establishing an efficient code management strategy.

The SQLiteMP project demonstrates a proof-of-concept implementation of an MP data model in SQLite. Building on the concepts and code presented in my earlier [SQLite SQL Tutorial][] - which includes SQL snippets for performing common MP operations on SQLite databases - this project leverages [views][SQLite View] and [triggers][SQLite Trigger] to encapsulate MP functionality directly within the database. These features provide capabilities similar to stored procedures, while the built-in JSON functionality enables the creation of a higher-level API, minimizing the application’s direct interaction with SQL.

Although this project extends the GitHub-Pages-based SQLite SQL Tutorial, an important motivation for creating a separate repository was to simplify setup and maintenance by avoiding GitHub Pages. The standard GitHub file browser offers a sufficiently user-friendly interface for navigation of small documentation bases, including automatic TOC generation for Markdown-formatted files.

See [docs][Overview] for further details.

<!-- References -->

[SQLite SQL Tutorial]: https://pchemguy.github.io/SQLite-SQL-Tutorial
[SQLite View]: https://sqlite.org/lang_createview.html
[SQLite Trigger]: https://sqlite.org/lang_createtrigger.html
[Overview]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/Overview.md
[README.md]: https://github.com/pchemguy/SQLiteMP/blob/main/README.md
[MP]: https://pchemguy.github.io/SQLite-SQL-Tutorial/mat-paths
[docs]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/
[SQL]: https://github.com/pchemguy/SQLiteMP/tree/main/sqlitemp/src/sqlitemp/sql
[MPops]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPops.md
[ParamViewTrigger]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/ParamViewTrigger.md
[CREATE]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopCREATE.md
[EXPORT]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopEXPORT.md
[DELETE]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopDELETE.md
[MODIFY]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPopMODIFY.md
[CoreSchema]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/CoreSchema.md
[StoredCode]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/StoredCode.md
[Step-by-Step Tutorial]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/Tutorial.md
[Debug]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/Tutorial.md#debugging-and-troubleshooting-sql