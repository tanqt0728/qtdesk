# Notices

QT/RustDesk Selfhost QT is a community maintenance and enhancement workspace for RustDesk-compatible self-host deployments.

This repository contains components derived from upstream open-source projects. Upstream copyright and license notices must remain in place.

## Upstream Components

- `rustdesk-api/`
  - Upstream: `lejianwen/rustdesk-api`
  - License in this repository: MIT, see `rustdesk-api/LICENSE`
  - Purpose: API server, admin APIs, web/admin resources, and self-host control plane.

- `rustdesk-server/`
  - Upstream: `lejianwen/rustdesk-server` / RustDesk server ecosystem code
  - License in this repository: AGPL-3.0, see `rustdesk-server/LICENSE`
  - Purpose: `hbbs`, `hbbr`, relay/rendezvous server compatibility, and API/JWT login patches.

- `rustdesk-api/resources/web/`
  - Contains bundled third-party web client and media/decoder assets from the upstream API project.
  - Additional notices are kept under `rustdesk-api/resources/web/assets/NOTICES` and related library license files.

## Project Branding

This repository may use names such as `rustdesk-selfhost-qt` or `RustDesk Selfhost QT` to describe a RustDesk-compatible self-host tooling distribution. It is not the official RustDesk project and is not endorsed by RustDesk.

## Source Availability

If modified AGPL-covered binaries or network services from `rustdesk-server/` are distributed or hosted, provide the corresponding source code for those modifications under AGPL-compatible terms.
