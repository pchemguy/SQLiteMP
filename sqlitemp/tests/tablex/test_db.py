# File: tests/test_db.py
import os
import sqlite3
import pytest
from tablex.db import DB

def test_resolve_uri_readonly(tmp_path):
    db_file = tmp_path / "test.db"
    raw_path, resolved_path, uri = DB._resolve_path_mode_uri(str(db_file), "READONLY")
    assert raw_path == str(db_file)
    assert resolved_path == os.path.abspath(str(db_file))
    assert uri == f"file:{resolved_path}?mode=ro"

def test_resolve_uri_readwrite(tmp_path):
    db_file = tmp_path / "test.db"
    raw_path, resolved_path, uri = DB._resolve_path_mode_uri(str(db_file), "RW")
    assert raw_path == str(db_file)
    assert resolved_path == os.path.abspath(str(db_file))
    assert uri == f"file:{resolved_path}?mode=rw"

def test_resolve_uri_w_mode(tmp_path):
    db_file = tmp_path / "test.db"
    raw_path, resolved_path, uri = DB._resolve_path_mode_uri(str(db_file), "W")
    assert raw_path == str(db_file)
    assert resolved_path == os.path.abspath(str(db_file))
    assert uri == f"file:{resolved_path}?mode=rwc"

def test_resolve_uri_memory():
    raw_path, resolved_path, uri = DB._resolve_path_mode_uri("ignored/path.db", "MEMORY")
    assert raw_path is None
    assert resolved_path is None
    assert "mode=memory" in uri

def test_connection_failure():
    # This test is expected to raise an error if trying to open a non-existent database
    # in read/write mode (rw) because the file does not exist.
    with pytest.raises(RuntimeError):
        # Using a temporary file that is guaranteed not to exist.
        DB("nonexistent_file.db", "RW")

def test_successful_connection_rw(tmp_path):
    # Create an empty file to satisfy the "rw" requirement.
    db_file = tmp_path / "existing.db"
    db_file.write_text("")  # Create an empty file.
    db = DB(str(db_file), "RW")
    assert isinstance(db.con, sqlite3.Connection)
    db.con.close()
