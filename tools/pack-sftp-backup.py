#!/usr/bin/env python3
"""
Pack files copied by SFTP from an old RustDesk API/server deployment into a
backup zip that the admin Smart import flow can inspect and restore.

This is useful when the old deployment has no backup-export endpoint and you
only have raw files such as rustdeskapi.db, config.yaml, and id_ed25519 keys.
"""

from __future__ import annotations

import argparse
import json
import sys
import time
import zipfile
from pathlib import Path


def add_if_exists(zf: zipfile.ZipFile, arcname: str, path: Path, components: set[str]) -> None:
    if not path or not path.exists():
        return
    zf.write(path, arcname)
    if arcname == "rustdeskapi.db":
        components.add("database")
    elif arcname == "config.yaml":
        components.add("config")
    elif arcname.startswith("server/"):
        components.add("server_keys")


def find_file(root: Path | None, filename: str) -> Path | None:
    if not root:
        return None
    direct = root / filename
    if direct.exists():
        return direct
    for candidate in root.rglob(filename):
        if candidate.is_file():
            return candidate
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description="Pack SFTP-copied RustDesk API/server files into an importable backup zip.")
    parser.add_argument("--root", help="Folder containing SFTP-copied files; searched recursively")
    parser.add_argument("--db", help="Path to rustdeskapi.db")
    parser.add_argument("--config", help="Path to config.yaml")
    parser.add_argument("--server-data", help="Folder containing id_ed25519 and id_ed25519.pub")
    parser.add_argument("--out", default="rustdesk-sftp-backup.zip", help="Output zip path")
    args = parser.parse_args()

    root = Path(args.root) if args.root else None
    db = Path(args.db) if args.db else find_file(root, "rustdeskapi.db")
    config = Path(args.config) if args.config else find_file(root, "config.yaml")
    server_data = Path(args.server_data) if args.server_data else root
    private_key = find_file(server_data, "id_ed25519")
    public_key = find_file(server_data, "id_ed25519.pub")

    components: set[str] = set()
    with zipfile.ZipFile(args.out, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        add_if_exists(zf, "rustdeskapi.db", db, components)
        add_if_exists(zf, "config.yaml", config, components)
        add_if_exists(zf, "server/id_ed25519", private_key, components)
        add_if_exists(zf, "server/id_ed25519.pub", public_key, components)
        manifest = {
            "version": 1,
            "created_at": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
            "components": [item for item in ["database", "config", "server_keys"] if item in components],
        }
        zf.writestr("manifest.json", json.dumps(manifest, indent=2).encode("utf-8"))

    if not components:
        Path(args.out).unlink(missing_ok=True)
        raise SystemExit("No backup files found. Provide --root or explicit --db/--config/--server-data paths.")

    print(f"Wrote {args.out}")
    print("Components:", ", ".join([item for item in ["database", "config", "server_keys"] if item in components]))
    print("Open the new admin Backup page, click Inspect backup, then Smart import.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
