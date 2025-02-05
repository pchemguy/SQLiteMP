WITH
	tables AS (
        SELECT sm.tbl_name AS table_name, ptl.schema, ptl.ncol, ptl.wr, ptl."strict", sm.sql
        FROM sqlite_master AS sm, pragma_table_list() AS ptl
        WHERE sm.type = 'table'
          AND sm.name NOT LIKE 'sqlite_%'
		  AND ptl.type = 'table'
		  AND sm.tbl_name = ptl.name
    ),
    columns AS (
        SELECT t.table_name, ptx.cid, ptx.name AS col_name,
               ptx.type, ptx."notnull", ptx.dflt_value, ptx.hidden, ptx.pk
        FROM tables AS t,
             pragma_table_xinfo(t.table_name) AS ptx
        ORDER BY t.table_name, ptx.cid
    ),	
    fkey_columns AS (
        SELECT t.table_name AS src_table, pfkl."from" AS src_col,
               pfkl."table" AS dst_table, pfkl."to" AS dst_col,
               pfkl.on_update, pfkl.on_delete, pfkl.id AS fk_id, pfkl.seq AS fk_seq
        FROM tables AS t,
             pragma_foreign_key_list(t.table_name) AS pfkl
        ORDER BY t.table_name, pfkl.id, pfkl.seq
    ),
    foreign_keys AS (
        SELECT src_table, json_group_array(src_col) AS src_cols,
               dst_table, json_group_array(dst_col) AS dst_cols,
               on_update, on_delete, fk_id
        FROM fkey_columns
        GROUP BY src_table, fk_id
        ORDER BY src_table, dst_table
    )
SELECT *
FROM foreign_keys;
