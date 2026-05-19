# QT Desk GitHub Publication Roadmap

Last updated: 2026-05-16

## Recommendation

Ship QT Desk first as a compliant, clearly attributed RustDesk-ecosystem distribution:

- QT Desk Control Plane: based on `lejianwen/rustdesk-api` under MIT.
- QT Desk Server Compatibility Pack: based on `lejianwen/rustdesk-server` / RustDesk server code under AGPL-3.0.
- QT Desk Web v3: original UI/control-plane work, while any reused web protocol assets stay attributed.
- QT Desk Native/Clean-room work: long-term track, clearly separated.

This is safer and faster than a full clean-room rewrite as the first public release.

## Why `lejianwen/rustdesk-api` Can Be MIT

`lejianwen/rustdesk-api` is an API/control-plane project. Its own source is MIT licensed.

That does not mean:

- RustDesk client is MIT.
- RustDesk server is MIT.
- RustDesk trademarks/logos can be reused freely as your own brand.
- A bundled modified RustDesk server/client can be relicensed as MIT.

It means the API project code itself can be used under MIT, provided the MIT notice is kept.

## Can QT Desk Be Used As The Project Name?

Yes, this is the safer direction.

Rules:

- Use QT Desk as your own project/product name.
- Do not use RustDesk logos/icons as QT Desk branding.
- Do not imply QT Desk is official RustDesk.
- Say "compatible with the RustDesk self-host ecosystem" or "based on/forked from ..." where accurate.
- Keep upstream notices and licenses.

## Repository Structure

Preferred public layout:

```text
QT-DESK/
  README.md
  NOTICE.md
  TRADEMARKS.md
  SECURITY.md
  LICENSES/
    MIT-lejianwen-rustdesk-api.txt
    AGPL-3.0-rustdesk-server.txt
    third-party/
  docs/
    derived-code-map.md
    github-publication-roadmap.md
    qt-desk-custom-client-plan.md
    qt-desk-clean-room-roadmap.md
  rustdesk-api/
  rustdesk-server/
  resources-or-web3-original-work/
  docker-compose.yml
  docker-compose.windows.yml
  .env.example
```

Root license:

- Do not put a single root `MIT` license if the repo contains AGPL server/client code.
- Use a root `README` saying "This repository contains components under multiple licenses. See `LICENSES/` and each component directory."

## Required Public Files

### `NOTICE.md`

Must include:

- QT Desk project copyright.
- `lejianwen/rustdesk-api` attribution.
- `lejianwen/rustdesk-server` / RustDesk server attribution.
- Any bundled web/decoder libraries attribution.
- Statement that upstream notices are preserved in component directories.

### `TRADEMARKS.md`

Must include:

- RustDesk is a trademark/name of its owners.
- QT Desk is not affiliated with, endorsed by, or sponsored by RustDesk.
- RustDesk names may appear only for compatibility/attribution.

### `docs/derived-code-map.md`

Must list:

- Which folders are upstream-derived.
- Upstream repo URL.
- Upstream commit/branch if known.
- Local changes summary.
- License for each folder.

### `SECURITY.md`

Must explain:

- Do not publish `.env`.
- Rotate all local JWT/admin/server secrets before public release.
- Server private key is sensitive.
- How to report vulnerabilities.

## GitHub Release Route

### Phase 1: Clean The Repo

- Remove `.env`.
- Remove local Chrome test profiles/artifacts.
- Remove generated backups, logs, DB files, private keys, tokens, installers.
- Keep `.env.example`.
- Add `.gitignore` coverage for secrets/artifacts.

### Phase 2: License Hygiene

- Add `NOTICE.md`.
- Add `TRADEMARKS.md`.
- Add `LICENSES/`.
- Add `docs/derived-code-map.md`.
- Keep original license files inside `rustdesk-api/` and `rustdesk-server/`.

### Phase 3: Rebrand Public Surface

- Rename README title to QT Desk.
- Describe it as a self-hosted remote access control plane compatible with RustDesk ecosystem components.
- Avoid "official RustDesk" language.
- Replace admin UI visible RustDesk branding with QT Desk where it is your own UI.
- Keep compatibility references where needed.

### Phase 4: Split Product Messaging

Use three labels:

- QT Desk Control Plane: MIT-derived API/admin/web work.
- QT Desk Server Compatibility Pack: AGPL-compatible server fork.
- QT Desk Web v3: original web control surface with compatibility bridge.

This makes licensing understandable.

### Phase 5: CI/CD

- Add GitHub Actions build for `rustdesk-api`.
- Add GitHub Actions build for `rustdesk-server`.
- Push Docker images only after secrets are removed.
- Tag images as:
  - `qtdesk/control-plane`
  - `qtdesk/server-compat`
- Add SBOM/checksum later.

### Phase 6: Public README

README should include:

- What QT Desk is.
- What it is not.
- Quick start.
- Security warning.
- License section.
- Attribution section.
- Roadmap.

Suggested wording:

> QT Desk is an open-source self-hosted remote access control plane and compatibility distribution. It includes components derived from `lejianwen/rustdesk-api` and RustDesk server ecosystem projects, with original QT Desk admin and Web v3 work. QT Desk is not affiliated with or endorsed by RustDesk.

## What Not To Do

- Do not remove upstream license files.
- Do not claim all code is MIT while AGPL code is present.
- Do not use RustDesk icon/logo for QT Desk.
- Do not publish `.env`, server keys, DB, admin tokens, OAuth secrets, or signing certs.
- Do not copy RustDesk Pro custom-client generator code, UI, or private assets.
- Do not say "no RustDesk relationship" while shipping derived code.

## Best Practical Plan

Public v0.1:

- QT Desk branding for your own admin/web/docs.
- Clear attribution and multi-license repo.
- Docker Compose working.
- Backup/restore working.
- Admin hardening started.
- Web v3 marked experimental.

Public v0.2:

- Custom Client Builder MVP.
- OAuth/2FA documentation.
- Better device/user UI.
- Docker Hub images.

Public v0.3:

- Native QTDP demo mode.
- OpenViking optional memory service.
- Clean-room module map.

Public v1.0:

- Polished admin.
- Reliable server deployment.
- Custom client build path.
- Web v3 stable enough for non-DRM desktop/control workloads.
