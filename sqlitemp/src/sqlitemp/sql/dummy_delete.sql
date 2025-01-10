-- ## Categories - `del_cat`
-- Data for categories to be deleted
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('del_cat', json('
                [
                    "/Assets/Diagrams",
                    "/Library/Drafts/DllTools/Dem - DLL/memtools",
                    "/Project/SQLiteDBdev",
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Item Associations - `del_item_cat`
-- Data for item associations to be deleted
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('del_item_cat', json('{
                "cat_path": "/Assets/Diagrams",
                "item_handles": [
                    "115d7db97e71b4ebba0388009cbf514b",
                    "25c7d52190cb287ce5333fbfb55fa62c",
                    "263d97ba77c87d8ff662c1cf471a54e3",
                    "26461fd16a254e5d7f54afa88a35ddf1",
                    "2b6292a5ce9f377df08da4687cb3eed8",
                    "305391763051ed220149f52f90cfa869",
                    "37befb150ae33ae8e0f7467ad9898c48",
                    "396e16c24fbade080482aaf84ef63cc5",
                    "5e26004e2f286e8e2d166bd8fc2f7684",
                ]            
            }'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Reset Item Associations - `reset_item_cat`
-- Data for item associations to be reset
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('reset_item_cat', json('
                [
                    "0764037c54441d43fc57d370dfe203e6",
                    "09ec2bbbb61735163017bee90e46aaed",
                    "2b25a438f79f9449101a5cb5abdb4d5f",
                    "396e16c24fbade080482aaf84ef63cc5",
                    "5f073b688ca9cf337876eea52afc04f5",
                    "5f6532836598595c39d75e403cff769f",
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Delete Items - `del_item`
-- Data for items to be deleted
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('del_item', json('
                [
                    "0764037c54441d43fc57d370dfe203e6",
                    "09ec2bbbb61735163017bee90e46aaed",
                    "2b25a438f79f9449101a5cb5abdb4d5f",
                    "396e16c24fbade080482aaf84ef63cc5",
                    "5f073b688ca9cf337876eea52afc04f5",
                    "5f6532836598595c39d75e403cff769f",
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
