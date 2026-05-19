#!/usr/bin/env python3
"""
Export selected data from an existing lejianwen/rustdesk-api SQLite database into
the selective backup format accepted by the QT/RustDesk self-host admin UI.

This is intentionally offline: it reads the old rustdeskapi.db directly and does
not require the old server to run new backup endpoints.
"""

from __future__ import annotations

import argparse
import json
import sqlite3
import sys
import time
import zipfile
from pathlib import Path
from typing import Any


COMPONENTS = {"database", "config", "server_keys", "users", "address_book", "devices", "logs"}


TABLE_ALIASES = {
    "oauth": ("oauths", "oauth"),
}


JSON_COLUMNS = {"tags", "permissions", "detail"}
BOOL_COLUMNS = {
    "is_admin",
    "auto_register",
    "pkce_enable",
    "force_always_relay",
    "online",
    "same_server",
    "is_file",
    "once",
}


RENAME_KEYS = {
    "force_always_relay": "forceAlwaysRelay",
    "rdp_port": "rdpPort",
    "rdp_username": "rdpUsername",
    "login_name": "loginName",
    "same_server": "sameServer",
}


def parse_components(raw: str) -> list[str]:
    requested = [item.strip() for item in raw.replace(";", ",").replace(" ", ",").split(",") if item.strip()]
    unknown = sorted(set(requested) - COMPONENTS)
    if unknown:
        raise SystemExit(f"Unknown components: {', '.join(unknown)}")
    return list(dict.fromkeys(requested))


def existing_tables(conn: sqlite3.Connection) -> set[str]:
    rows = conn.execute("select name from sqlite_master where type='table'").fetchall()
    return {row[0] for row in rows}


def resolve_table(tables: set[str], name: str) -> str | None:
    for candidate in TABLE_ALIASES.get(name, (name,)):
        if candidate in tables:
            return candidate
    return None


def table_rows(conn: sqlite3.Connection, tables: set[str], table: str) -> list[dict[str, Any]]:
    resolved = resolve_table(tables, table)
    if not resolved:
        return []
    rows = conn.execute(f'select * from "{resolved}"').fetchall()
    return [normalize_row(dict(row)) for row in rows]


def normalize_row(row: dict[str, Any]) -> dict[str, Any]:
    out: dict[str, Any] = {}
    for key, value in row.items():
        json_key = RENAME_KEYS.get(key, key)
        if isinstance(value, bytes):
            value = value.decode("utf-8", errors="replace")
        if key in BOOL_COLUMNS and value is not None:
            value = bool(value)
        if key in JSON_COLUMNS:
            value = parse_json_value(value)
        out[json_key] = value
    return out


def parse_json_value(value: Any) -> Any:
    if value is None or value == "":
        return []
    if isinstance(value, (dict, list)):
        return value
    try:
        return json.loads(value)
    except (TypeError, json.JSONDecodeError):
        return []


def add_json(zf: zipfile.ZipFile, name: str, value: Any) -> None:
    payload = json.dumps(value, ensure_ascii=False, indent=2, default=str).encode("utf-8")
    zf.writestr(name, payload)


def add_file_if_exists(zf: zipfile.ZipFile, arcname: str, path: Path) -> bool:
    if not path.exists():
        return False
    zf.write(path, arcname)
    return True


def build_users(conn: sqlite3.Connection, tables: set[str]) -> dict[str, Any]:
    return {
        "users": table_rows(conn, tables, "users"),
        "groups": table_rows(conn, tables, "groups"),
        "device_groups": table_rows(conn, tables, "device_groups"),
        "user_thirds": table_rows(conn, tables, "user_thirds"),
        "oauth": table_rows(conn, tables, "oauth"),
    }


def build_address_book(conn: sqlite3.Connection, tables: set[str]) -> dict[str, Any]:
    return {
        "address_books": table_rows(conn, tables, "address_books"),
        "collections": table_rows(conn, tables, "address_book_collections"),
        "collection_rules": table_rows(conn, tables, "address_book_collection_rules"),
        "tags": table_rows(conn, tables, "tags"),
    }


def build_devices(conn: sqlite3.Connection, tables: set[str]) -> dict[str, Any]:
    return {"peers": table_rows(conn, tables, "peers")}


def build_logs(conn: sqlite3.Connection, tables: set[str]) -> dict[str, Any]:
    return {
        "login_logs": table_rows(conn, tables, "login_logs"),
        "audit_conn": table_rows(conn, tables, "audit_conns"),
        "audit_file": table_rows(conn, tables, "audit_files"),
        "share_records": table_rows(conn, tables, "share_records"),
        "web_v3_sessions": table_rows(conn, tables, "web_v3_sessions"),
        "web_v3_shares": table_rows(conn, tables, "web_v3_shares"),
        "web_v3_audit": table_rows(conn, tables, "web_v3_audits"),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Create a selective backup zip from a legacy rustdesk-api SQLite DB.")
    parser.add_argument("--db", required=True, help="Path to the old rustdeskapi.db")
    parser.add_argument("--out", default="rustdesk-legacy-selected-backup.zip", help="Output zip path")
    parser.add_argument(
        "--components",
        default="users,address_book,devices",
        help="Comma-separated components: database,config,server_keys,users,address_book,devices,logs",
    )
    parser.add_argument("--config", help="Optional old config.yaml path, used when component config is selected")
    parser.add_argument("--server-data", help="Optional folder containing id_ed25519 and id_ed25519.pub")
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        raise SystemExit(f"Database not found: {db_path}")
    components = parse_components(args.components)

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        tables = existing_tables(conn)
        with zipfile.ZipFile(args.out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            add_json(zf, "manifest.json", {
                "version": 1,
                "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "components": components,
            })
            if "database" in components:
                zf.write(db_path, "rustdeskapi.db")
            if "config" in components and args.config:
                add_file_if_exists(zf, "config.yaml", Path(args.config))
            if "server_keys" in components and args.server_data:
                server_dir = Path(args.server_data)
                add_file_if_exists(zf, "server/id_ed25519", server_dir / "id_ed25519")
                add_file_if_exists(zf, "server/id_ed25519.pub", server_dir / "id_ed25519.pub")
            if "users" in components:
                add_json(zf, "data/users.json", build_users(conn, tables))
            if "address_book" in components:
                add_json(zf, "data/address_book.json", build_address_book(conn, tables))
            if "devices" in components:
                add_json(zf, "data/devices.json", build_devices(conn, tables))
            if "logs" in components:
                add_json(zf, "data/logs.json", build_logs(conn, tables))
    finally:
        conn.close()

    print(f"Wrote {args.out}")
    print("Import it from the new admin Backup page with the same selected components.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
