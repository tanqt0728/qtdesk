# rustdesk-selfhost-qt

Enhanced self-host control plane, Web v3 experiments, backup/restore, and custom-client tooling for RustDesk-compatible deployments.

This is not the official RustDesk project. See `NOTICE.md`, `TRADEMARKS.md`, and `docs/derived-code-map.md`.

## Upstream

This repository keeps the original copyright and license notices in each
upstream project.

- `rustdesk-api`: forked from `lejianwen/rustdesk-api`
- `rustdesk-server`: forked from `lejianwen/rustdesk-server`, using the
  `forapi` branch for API integration patches

Current fork remotes in this workspace point to:

- `https://github.com/tanqt0728/rustdesk-api.git`
- `https://github.com/tanqt0728/rustdesk-server.git`

## Goals

- Restore full compatibility with RustDesk client `1.4.1+`.
- Keep the API login flow working with `MUST_LOGIN=Y` on the server side.
- Restore and maintain WebClient v1 on port `21114`.
- Provide a professional Web Admin dashboard for day-to-day management.
- Make config/database export and import easy from Web Admin.
- Keep server and API deployable as separate Docker services.

Suggested image names:

- `tanqt0728/rustdesk-selfhost-qt-server:latest`
- `tanqt0728/rustdesk-selfhost-qt-api:latest`

## Deployment Model

The previous single all-in-one image is intentionally replaced by two services:

- `rustdesk-server`: `hbbs` + `hbbr`, built from `./rustdesk-server`
- `rustdesk-api`: Go API + Web Admin + WebClient v1, built from `./rustdesk-api`

Copy `.env.example` to `.env`, change all secrets, then run:

```sh
docker compose up -d --build
```

On Windows with Docker Desktop, use the Windows override so the server ports are
published explicitly instead of relying on Linux host networking:

```sh
docker compose --env-file .env -f docker-compose.yml -f docker-compose.windows.yml up -d --build
```

For cloud or public hosting, use the admin split override so the public API/Web v3 port does not expose the admin UI or admin API:

```sh
docker compose --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.windows.yml \
  -f docker-compose.admin-split.yml \
  up -d --build
```

Default split-mode listeners:

- Public API/Web v3: `http://<host>:21114`
- Private admin: `http://127.0.0.1:21124/_admin/`

Change the private admin bind in `.env`:

```env
RUSTDESK_API_ADMIN_ADDR=0.0.0.0:21124
RUSTDESK_API_ADMIN_HOST_PORT=127.0.0.1:21124
```

For a cloud server, publish `21124` only to localhost, VPN, Tailscale/ZeroTier, SSH tunnel, or a reverse proxy with IP allowlisting and HTTPS.

See `docs/production-deployment.md` for port exposure, SSH tunnel, Caddy, Nginx,
and migration examples.

See `docs/docker-publishing.md` for GitHub Actions image publishing to GHCR and
optional Docker Hub.

Rebuild only one side when needed:

```sh
docker compose build rustdesk-server
docker compose up -d rustdesk-server

docker compose build rustdesk-api
docker compose up -d rustdesk-api
```

## Compatibility Work

Priority 1 is RustDesk client `1.4.1+` API login compatibility.

Known failure mode: client login succeeds through API, but API-authenticated
connections do not reach the target host while plain ID/password direct
connections still work.

Areas to inspect:

- `rustdesk-server/src/rendezvous_server.rs`
- `rustdesk-server/src/relay_server.rs`
- `rustdesk-server/src/jwt.rs`
- `rustdesk-api/http/controller/api`
- `rustdesk-api/http/middleware/rustauth.go`
- `rustdesk-api/service/loginLog.go`

The intended server-side baseline is the official `rustdesk/rustdesk-server`
`1.1.15` WebSocket/JWT/session behavior, merged carefully into this `forapi`
branch.

Verified locally with two RustDesk `1.4.6` clients: API login plus remote
connection succeeds with `MUST_LOGIN=Y`.

Priority 2 is WebClient v1 maintenance. WebClient v2 was removed upstream, so
this repository should avoid copying removed code and instead keep v1 working
or reimplement compatible behavior cleanly. A known WebClient failure mode is
launching a remote session and being sent to `127.0.0.1`; the current API now
injects the configured public API URL and falls back to the actual request host
when the config still contains localhost.

`lichon/rustdesk-web-ts` is a possible future WebClient direction because it is
a React/Vite/TypeScript web remote client, but it is not a direct replacement
for the admin console. Treat it as a separate integration track.

## Web Admin

In local all-in-one mode, the bundled admin entry is available at:

```text
http://<api-host>:21114/_admin/
```

In admin split mode, use:

```text
http://127.0.0.1:21124/_admin/
```

In split mode, `/_admin/` and `/api/admin/*` are intentionally not registered on public port `21114`.

Current admin features:

- Login with the RustDesk admin account.
- Dashboard with devices, users, audit counts and server config.
- Device, user and connection-audit tables.
- WebClient shortcut.
- Full and component backup export/import under `Backup`.
- Custom Clients MVP that generates managed client profiles, config strings, Windows deployment scripts, and downloadable deployment packages.

Full backup export downloads a zip containing:

- `rustdeskapi.db`
- `config.yaml`
- server public/private key files when available

Component backup lets you export or restore only selected parts:

- users, password hashes, OAuth settings, and OAuth account links
- address book entries, saved address-book passwords, collections, rules, and tags
- devices
- logs and audit records
- API config
- server keypair
- full raw database

For migration from an older `lejianwen/rustdesk-api` SQLite database, create a
compatible selected backup offline:

```sh
python tools/export-legacy-rustdesk-api.py \
  --db /path/to/old/rustdeskapi.db \
  --out rustdesk-legacy-selected-backup.zip \
  --components users,address_book,devices
```

Then open the new admin `Backup` page and use `Inspect backup` to preview what
the zip contains, including detected components, record counts, files, sensitive
data, and restart impact. Use `Smart import` to read the backup manifest when
present, or restore the recognizable files in the zip when no manifest exists.
Use `Import selected` only when you intentionally want to force a subset.
Restore users and address book together when you want saved credentials to keep
matching the same user IDs.

If your old server only has files copied by SFTP, pack them first:

```sh
python tools/pack-sftp-backup.py \
  --root /path/to/sftp-copy \
  --out rustdesk-sftp-backup.zip
```

Backup import accepts the same zip format. Restart the API container after a
full database, config, or server-key import so the restored files are loaded
cleanly.

The compose file persists both `/app/data` and `/app/conf` with named volumes,
so imported database and config files survive container recreation.

## Custom Client Packages

The admin `Custom Clients` page can download a deployment package containing a
profile JSON, RustDesk config string, Windows PowerShell apply script, and
settings files. This is still a configuration/deployment package, not a branded
binary builder.

See `docs/custom-client-packages.md`.

## Local Test Checklist

1. Install Docker Desktop with Linux containers enabled.
2. Copy `.env.example` to `.env`.
3. Set `RUSTDESK_RELAY_PUBLIC` to the address your test clients can reach, for
   example `192.168.1.50:21117` on LAN.
4. Set `RUSTDESK_API_PUBLIC_URL`, for example `http://192.168.1.50:21114`.
5. Generate a new `RUSTDESK_API_JWT_KEY`; do not reuse a value pasted into chat
   or logs.
6. Start with the Windows compose command above.
7. Open `http://127.0.0.1:21114` for the API admin/WebClient.
8. Configure RustDesk clients to use your local ID/relay/API settings and test:
   login, address book sync, online status, direct connection, relay connection,
   and WebClient launch.

## Public GitHub Checklist

Before pushing a public repository:

1. Run the local publication check:

   ```powershell
   powershell -ExecutionPolicy Bypass -File tools\check-public-ready.ps1
   ```

2. Do not commit `.env`, DB files, backup zips, server keys, OAuth secrets, admin tokens, or browser test profiles.
3. Keep `rustdesk-api/LICENSE` and `rustdesk-server/LICENSE`.
4. Keep `NOTICE.md`, `TRADEMARKS.md`, `SECURITY.md`, and `docs/derived-code-map.md` updated.
5. Do not claim the whole repository is MIT while AGPL-covered server code is included.
6. Do not use RustDesk logos/icons as this project's own branding.
7. Rotate secrets if they were ever pasted into chat, logs, screenshots, or Git history.

`rustdesk-api-v2/` is a local reference copy and is ignored by default. Do not include it in the first public push unless you have a specific reason.

## Licenses

This repository contains multiple licensed components:

- `rustdesk-api/`: MIT, see `rustdesk-api/LICENSE`
- `rustdesk-server/`: AGPL-3.0, see `rustdesk-server/LICENSE`
- bundled web/media assets: see component notice files

See `LICENSES/README.md` and `NOTICE.md`.
