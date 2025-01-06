# High Level API

## Retrieve Descendant Categories

Let's start 

```sql
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_cat_descendants', json('[' ||
                '"/Assets/Diagrams",'                              ||
                '"/Library/Drafts/DllTools/Dem - DLL/memtools",'   ||
                '"/Project/SQLiteDBdev",'                          ||
            ']'))
    )
SELECT * FROM json_ops;
```

---

| [**<= Materialized path operations**][MPops] | [**Next: High Level API =>**][MPops] |
| -------------------------------------------- | ------------------------------------ |


<!-- References -->

[MPops]: https://github.com/pchemguy/SQLiteMP/blob/main/sqlitemp/docs/MPops.md