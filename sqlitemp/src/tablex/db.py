"""
Module: db
Description: Defines the DB class for managing SQLite connection objects.
"""

import os
import sqlite3
from typing import Optional, Tuple


class DB:
    """
    A class to manage an SQLite connection.

    Attributes:
        con (sqlite3.Connection): The active SQLite connection.
    """

    def __init__(self, db_path: str, mode: str) -> None:
        """
        Initializes a DB instance by resolving the database path and mode,
        generating the corresponding URI, and opening the SQLite connection.

        Args:
            db_path (str): The path to the SQLite database file (ignored for MEMORY mode).
            mode (str): The mode of operation; allowed values are:
                        "READONLY", "RO", "READWRITE", "RW", "W", or "MEMORY".

        Raises:
            ValueError: If an unsupported mode is provided.
            RuntimeError: If the SQLite connection cannot be established.
        """
        mode = mode.upper()
        allowed_modes = {"READONLY", "RO", "READWRITE", "RW", "W", "MEMORY"}
        if mode not in allowed_modes:
            raise ValueError(
                f"Unsupported mode: {mode}. Allowed modes: {', '.join(sorted(allowed_modes))}"
            )

        # Resolve path, mode, and URI using the dedicated routine.
        self.__raw_path, self.__resolved_path, self.__uri = self._resolve_path_mode_uri(db_path, mode)
        self.__mode = mode

        # Attempt to open the SQLite connection using the generated URI.
        try:
            self.con = sqlite3.connect(self.__uri, uri=True)
        except sqlite3.Error as e:
            raise RuntimeError(f"Error opening SQLite connection with URI {self.__uri}") from e

    @staticmethod
    def _resolve_path_mode_uri(db_path: str, mode: str) -> Tuple[Optional[str], Optional[str], str]:
        """
        Resolves the database path and mode to generate an appropriate URI string.

        This routine is responsible for:
          - Converting a relative path to an absolute path (if applicable).
          - Mapping the provided mode to the correct SQLite URI mode parameter.
          - Generating the full URI string to be used for the connection or with the ATTACH statement.

        Args:
            db_path (str): The raw database path.
            mode (str): The mode of operation ("READONLY"/"RO", "READWRITE"/"RW", "W", or "MEMORY").

        Returns:
            tuple: A tuple (raw_path, resolved_path, uri) where:
                - raw_path (Optional[str]): The original database path (None for MEMORY mode).
                - resolved_path (Optional[str]): The absolute path (None for MEMORY mode).
                - uri (str): The URI string for connecting to SQLite.
        """
        if mode == "MEMORY":
            raw_path = None
            resolved_path = None
            # Generate an in-memory URI with shared cache.
            uri = "file:memdb1?mode=memory&cache=shared"
        else:
            raw_path = db_path
            resolved_path = os.path.abspath(os.path.expanduser(db_path))
            if mode in ("READONLY", "RO"):
                # Generate a URI for a read-only connection.
                uri = f"file:{resolved_path}?mode=ro"
            elif mode in ("READWRITE", "RW"):
                # Generate a URI for a read/write connection (the file must exist).
                uri = f"file:{resolved_path}?mode=rw"
            elif mode == "W":
                # Generate a URI that allows read/write and creates the file if it does not exist.
                uri = f"file:{resolved_path}?mode=rwc"
            else:
                # This branch should not be reached due to earlier validation.
                raise ValueError(f"Unhandled mode: {mode}")
        return raw_path, resolved_path, uri

    def __del__(self) -> None:
        """
        Destructor to close the SQLite connection when the object is garbage-collected.
        """
        try:
            if hasattr(self, "con") and self.con:
                self.con.close()
        except Exception:
            # Suppress any exceptions during cleanup.
            pass
