# QT Desk Custom Client Plan

Last updated: 2026-05-16

## Goal

Build an open-source QT Desk client distribution flow that can create preconfigured desktop/mobile clients similar to RustDesk Pro custom clients, while avoiding RustDesk trademark confusion and complying with upstream licenses.

## Legal And Branding Boundary

- Do not use the RustDesk name, logo, icon, screenshots, or marketing copy as QT Desk branding.
- Keep upstream copyright and license notices in every forked component.
- RustDesk client and `rustdesk-server` are AGPL-3.0 derived work territory. If QT Desk distributes modified binaries or hosts modified AGPL network services, publish the corresponding source under AGPL-compatible terms.
- `rustdesk-api` in this workspace is MIT licensed, but it must still retain its upstream copyright notice.
- Rename the product honestly as a fork/derived project until enough code is replaced to call it independent.
- Add a clear `NOTICE` / `ATTRIBUTION` file before public GitHub release.

## Product Target

Admin page: `Custom Clients`

Builder form:

- Platform:
  - Windows EXE
  - Windows MSI
  - macOS Intel
  - macOS Apple Silicon
  - Linux AppImage / deb / rpm where feasible
  - Android later
- Application name: `QT Desk`
- Package/bundle identifiers:
  - Windows UpgradeCode/ProductName
  - macOS bundle identifier
  - Linux desktop id
  - Android application id later
- Branding:
  - app icon
  - tray icon
  - logo
  - about text
  - support URL
  - update URL
- Server preset:
  - ID server
  - relay server
  - API server
  - public key
  - allow websocket
- Connection type:
  - Bidirectional
  - Incoming-only
  - Outgoing-only
- Lockdown options:
  - disable installation
  - hide settings
  - hide security/network/server settings
  - hide address book
  - force relay / disable TCP listen
  - disable user account login
  - disable file transfer
  - disable clipboard
  - disable terminal/camera/audio/printer
- Security:
  - optional preset password
  - force random password
  - approve mode
  - access mode
  - 2FA/trusted-device behavior where supported
- Advanced settings:
  - default settings list
  - override settings list
  - raw key/value editor for documented RustDesk options

## Technical Strategy

### Phase A: Safe Wrapper Builder

This avoids deep client source edits at first.

- Generate official/fork client config strings.
- Generate deployment scripts for Windows/macOS/Linux.
- Generate Windows MSI transform or wrapper installer that:
  - installs QT Desk binaries
  - applies config via `--config`
  - writes managed settings where supported
  - installs shortcuts with QT Desk branding
- Provide a signed artifact pipeline when the user supplies signing certs.

### Phase B: Source Fork Rebrand

Fork the AGPL RustDesk client source as `qt-desk-client`.

- Replace app name, icons, bundle IDs, package metadata, update URLs, about URLs.
- Remove public RustDesk server defaults.
- Preload QT Desk server config from build-time generated files.
- Add compile-time feature flags:
  - incoming-only
  - outgoing-only
  - bidirectional
  - disable install
  - disable settings sections
  - disable account UI
  - default/override policy injection
- Keep `AGPL-3.0` and notices.

### Phase C: Admin Integrated Build Farm

Add a controlled build worker.

- `qt-client-builder` Docker image for Linux builds.
- Windows build runner through GitHub Actions self-hosted runner or manual Windows builder.
- macOS builds through GitHub Actions macOS runners or developer machine.
- Artifact storage in API data volume.
- Build logs, checksum, signing status, and download links in admin.

### Phase D: Long-Term Clean Room Replacement

Only needed if QT Desk should become legally and technically independent from RustDesk.

- Keep protocol compatibility at first.
- Gradually replace UI/app shell with original QT Desk code.
- Keep or replace capture/input/network modules one by one.
- This is a long project; expect months, not days.

## Public GitHub Release Checklist

- Rename repo and README to QT Desk.
- Add `LICENSES/` folder for each component.
- Add `NOTICE.md` with upstream attribution.
- Add `TRADEMARKS.md` saying RustDesk is not our mark and QT Desk is not affiliated with RustDesk.
- Remove RustDesk logos/icons from QT Desk-branded binaries.
- Keep source available for every AGPL binary and network service.
- Do not include private `.env`, signing certificates, server private keys, or admin tokens.
- Add Docker Hub/GitHub Actions builds after secrets are cleaned.

## First Implementation Slice

1. Add admin navigation for `Custom Clients`.
2. Add backend models for client build profiles.
3. Add UI form for Windows first:
   - app name
   - connection type
   - server preset
   - lockdown toggles
   - default/override settings
4. Generate a config string and deployment script.
5. Later attach real fork-client build artifacts.
