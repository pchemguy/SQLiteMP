-- ## Categories - `new_cat`
-- Data for preparing the list of new categories
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('new_cat', json_array(
                json_object('path', '/Assets/Diagrams'),
                json_object('path', '/BAZ/bld/tcl/tests/manYYY/etc'),
                json_object('path', '/Library/DllTools/CPUInfo/x32'),
                json_object('path', '/Library/DllTools/Dem - DLL/AddLib/docs'),
                json_object('path', '/Library/DllTools/Dem - DLL/AddLib/x32'),
                json_object('path', '/Library/DllTools/Dem - DLL/AddLib/x64'),
                json_object('path', '/Library/DllTools/Dem - DLL/memtools'),
                json_object('path', '/Project/SQLite/Checks'),
                json_object('path', '/Project/SQLite/Fixtures'),
                json_object('path', '/Project/SQLite/MetaSQL/Examples'),
                json_object('path', '/safe/moduleAAAAA'),
                json_object('path', '/safe/moduleBBBBB')
            ))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Items - `new_item`
-- Data for preparing the list of new items
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('new_item', json('
                [
                    {
                        "handle": "e102a4954b60ebf024498b87b033c961A",
                        "handle_type": "md5",
                        "name": "MemtoolsLib.sh"
                    },
                    {
                        "handle": "fb351622f997ec7686e1cd0079dbccaA",
                        "handle_type": "md5",
                        "name": "ColumnsEx.doccls"
                    },
                    {
                        "handle": "df5965bd43b2dd9b3c78428330136ec0A",
                        "handle_type": "md5",
                        "name": "addclient.c"
                    },
                ]            
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;

-- ## Item Associations - `new_item_cat`
-- Data for preparing the list of new item associations
WITH
    json_ops(op_name, json_op) AS (
        VALUES
            ('new_item_cat', json('
                [
                    {
                        "cat_path": "/Assets",
                        "item_handles": [
                            "f1281500266a0c49737643580e91f188",
                            "ec5b638f0f2e1d3e70a404008b766145",
                            "e8e18009c40bf038603f86b4d7d8c712",
                            "fe207105e0f7ad3d6861742bc5030f79",
                        ]
                    },
                    {
                        "cat_path": "/Assets/Diagrams",
                        "item_handles": [
                            "ea656b9ffb993e6fd6d115af0d335cd2",
                            "e8ec0b1284b6bfba26703fe87874e185",
                            "e829a9ebe06e47ec764c421ba8550aff",
                        ]
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/AddLib",
                        "item_handles": ["df5965bd43b2dd9b3c78428330136ec00"]
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/AddLib/docs",
                        "item_handles": [
                            "f44c82c9953acda15a1b2ff73a0d4ca00",
                            "fdc86b4a4b2332606fc5cef72969b10a0",
                        ]
                    },
                    {
                        "cat_path": "/Library/DllTools/Dem - DLL/memtools",
                        "item_handles": ["e102a4954b60ebf024498b87b033c9610"]
                    },
                    {
                        "cat_path": "/Project/SQLite/Checks",
                        "item_handles": ["d2d3a850f6495f38ee6961d4eee2c5ee"]
                    },
                    {
                        "cat_path": "/Project/SQLite/Fixtures",
                        "item_handles": [
                            "d6b43bf13d30207b5147d8ecaa5f230c",
                            "ff05b9ccc2185c93d1acf00bb3dbdf73",
                        ]
                    },
                    {
                        "cat_path": "/Project/SQLite/MetaSQL/Examples",
                        "item_handles": [
                            "e84a16319e2a7a2f001996ea610b91d2",
                            "fb351622f997ec7686e1cd0079dbccab",
                            "d10a1b89819187b75515de6c3400c417",
                        ]
                    },
                    {
                        "cat_path": "/BAZ/bld",
                        "item_handles": ["f1281500266a0c49737643580e91f188"]
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests",
                        "item_handles": [
                            "df5965bd43b2dd9b3c78428330136ec00",
                            "e102a4954b60ebf024498b87b033c9610",
                            "e829a9ebe06e47ec764c421ba8550aff",
                        ]
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests/manYYY",
                        "item_handles": [
                            "f44c82c9953acda15a1b2ff73a0d4ca01",
                             "ec4d23b69f463d8314adfec69748354e",
                        ]
                    },
                    {
                        "cat_path": "/BAZ/bld/tcl/tests/manYYY/etc",
                        "item_handles": ["fdc86b4a4b2332606fc5cef72969b10a1"]
                    },
                ]
            '))
    )
INSERT INTO hierarchy_ops(op_name, json_op)
SELECT * FROM json_ops;
