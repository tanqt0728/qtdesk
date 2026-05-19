# Derived Code Map

Last updated: 2026-05-16

This document tracks which parts of the repository are upstream-derived and which parts are project-specific additions. Keep it updated before public releases.

## `rustdesk-api/`

- Upstream project: `lejianwen/rustdesk-api`
- License: MIT, see `rustdesk-api/LICENSE`
- Local purpose: API server, admin APIs, Web Admin, WebClient assets, backup/restore, Web v3 integration.
- Local changes include:
  - Docker build from local source.
  - Split server/API deployment support.
  - Admin dashboard redesign.
  - Backup export/import additions.
  - Web v3 backend/session/share/audit skeleton.
  - Web v3 static app and RustDesk web compatibility bridge.
  - Admin Settings save endpoint.
  - Custom Clients configuration generator MVP.
  - Optional admin/API split listener.

## `rustdesk-server/`

- Upstream project: `lejianwen/rustdesk-server` / RustDesk server ecosystem code
- License: AGPL-3.0, see `rustdesk-server/LICENSE`
- Local purpose: `hbbs`/`hbbr` server compatibility for RustDesk clients and API login.
- Local changes include:
  - JWT token normalization.
  - API-auth diagnostics without secret logging.
  - Docker/s6 split service runtime.
  - Compatibility fixes for RustDesk client `1.4.1+` login and connection flow.

## `rustdesk-api/resources/web/`

- Origin: bundled upstream web client assets from the API project.
- License/notices: see `rustdesk-api/resources/web/assets/NOTICES` and library-specific files under `resources/web`.
- Local purpose: legacy WebClient compatibility and protocol runtime currently used by Web v3 compatibility mode.

## `rustdesk-api/resources/web3/`

- Origin: project-specific Web v3 work in this repository.
- License: follows the repository/component license policy for the API project unless separated later.
- Important note: current Web v3 can still load the legacy RustDesk web protocol bundle from `resources/web`, so it is not yet a fully clean-room remote protocol implementation.

## Root Docker/Docs/Tools

- Origin: project-specific deployment and maintenance work.
- Files include:
  - `docker-compose.yml`
  - `docker-compose.windows.yml`
  - `docker-compose.admin-split.yml`
  - `docs/`
  - `tools/`
  - root README/security/notice files

## Clean-Room Future

New QT Desk-native protocol/client/server work should be placed in new clearly named modules and documented in `docs/qt-desk-clean-room-roadmap.md`.
