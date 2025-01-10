-- ## Descendant Categories - `ls_cat_desc`
-- Data for retrieving descendant categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_cat_desc', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Child Categories - `ls_cat_child`
-- Data for retrieving child categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_cat_child', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Descendant Items - `ls_item_desc`
-- Data for retrieving descendant items
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_item_desc', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Child Items - `ls_item_desc`
-- Data for retrieving child items
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_item_child', json('[' || concat_ws(',',
                '"/Assets/Diagrams"',
                '"/Library/Drafts/DllTools/Dem - DLL/memtools"',
                '"/Project/SQLiteDBdev"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Item Associations - `ls_item_cat`
-- Data for retrieving item associations
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('ls_item_cat', json('[' || concat_ws(',',
                '"0764037c54441d43fc57d370dfe203e6"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Item Association Counts - `cnt_item_cat`
-- Data for retrieving item association counts
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('cnt_item_cat', json('[' || concat_ws(',',
                '"007ebc73169d3cfd9c72ff3cefdfae560"',
                '"08f17f6155577f349cb26709ffc8c189"',
                '"0932de56b45b0d77f39fac31427491f4"',
                '"09ec2bbbb61735163017bee90e46aaed1"',
                '"0764037c54441d43fc57d370dfe203e6"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Child Items  Association Counts - `cnt_item_child_cat`
-- Data for retrieving child items association counts
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('cnt_item_child_cat', json('[' || concat_ws(',',
				'"/Project/SQLite/MetaSQL/Examples"',
                '"/Assets/Diagrams"'
            ) || ']'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
