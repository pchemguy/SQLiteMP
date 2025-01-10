-- ## Move Item Associations - `mv_item_cat`
-- Data for item associations to be moved
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('mv_item_cat', json('{
                "cat_path": "/Assets/Diagrams",
                "new_path": "/Project/SQLite",                
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

-- ## Move Trees - `mv_tree`
-- Data for tree move
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('mv_tree', json('[
                {"path_old":"/BAZ/bld/booze/safe00",     "path_new":"/bbbbbb"},
                {"path_old":"/BAZ/bld/tcl/tests/safe00", "path_new":"/safe00"},
                {"path_old":"/safe00",                   "path_new":"/safe"},
                {"path_old":"/BAZ/dev/msys2",            "path_new":"/BAZ/dev/msys"},
                {"path_old":"/BAZ/bld/tcl/tests/preEEE", "path_new":"/preEEE"},
                {"path_old":"/safe/modules",             "path_new":"/safe/modu"},
                {"path_old":"/safe/modu/mod2",           "path_new":"/safe/modu/mod3"},
                {"path_old":"/BAZ/bld/tcl/tests/ssub00", "path_new":"/safe/ssub00"},
                {"path_old":"/BAZ/dev/msys/mingw32",     "path_new":"/BAZ/dev/msys/nix"},
                {"path_old":"/safe/ssub00/modules",      "path_new":"/safe/modules"},
                {"path_old":"/BAZ/bld/tcl/tests/manYYY", "path_new":"/man000"},
                {"path_old":"/BAZ/dev/msys/nix/etc",     "path_new":"/BAZ/dev/msys/nix/misc"},
                {"path_old":"/BAZ/bld/tcl/tests/manZZZ", "path_new":"/BAZ/bld/tcl/tests/man000"},
                {"path_old":"/BAZ/bld/tcl/tests/man000", "path_new":"/man000"},
                {"path_old":"/BAZ/bld/tcl/tests/safe11", "path_new":"/safe11"},
            ]'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Copy Trees - `cp_tree`
-- Data for tree copy
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('cp_tree', json('[
                {"path_old":"/copyBAZ/bld/booze/safe00",     "path_new":"/copybbbbbb"},
                {"path_old":"/copyBAZ/bld/tcl/tests/safe00", "path_new":"/copysafe00"},
                {"path_old":"/copysafe00",                   "path_new":"/copysafe"},
                {"path_old":"/copyBAZ/dev/msys2",            "path_new":"/copyBAZ/dev/msys"},
                {"path_old":"/copyBAZ/bld/tcl/tests/preEEE", "path_new":"/copypreEEE"},
                {"path_old":"/copysafe/modules",             "path_new":"/copysafe/modu"},
                {"path_old":"/copysafe/modu/mod2",           "path_new":"/copysafe/modu/mod3"},
                {"path_old":"/copyBAZ/bld/tcl/tests/ssub00", "path_new":"/copysafe/ssub00"},
                {"path_old":"/copyBAZ/dev/msys/mingw32",     "path_new":"/copyBAZ/dev/msys/nix"},
                {"path_old":"/copysafe/ssub00/modules",      "path_new":"/copysafe/modules"},
                {"path_old":"/copyBAZ/bld/tcl/tests/manYYY", "path_new":"/copyman000"},
                {"path_old":"/copyBAZ/dev/msys/nix/etc",     "path_new":"/copyBAZ/dev/msys/nix/misc"},
                {"path_old":"/copyBAZ/bld/tcl/tests/manZZZ", "path_new":"/copyBAZ/bld/tcl/tests/man000"},
                {"path_old":"/copyBAZ/bld/tcl/tests/man000", "path_new":"/copyman000"},
                {"path_old":"/copyBAZ/bld/tcl/tests/safe11", "path_new":"/copysafe11"},
            ]'))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
