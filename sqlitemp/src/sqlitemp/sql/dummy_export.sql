-- ## Categories - `exp_cat`
-- Data for exporting categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('exp_cat', json('[
                "/Assets/Diagrams",
                "/Library/Drafts/DllTools/Dem - DLL/memtools",
                "/Project/SQLiteDBdev",
            ]'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
