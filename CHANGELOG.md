# Changelog

## 2026-05-21

### VPS and Image Publishing

- Published the project from `tanqt0728/qtdesk` with submodules for the API and server forks.
- Switched Docker image publishing to Docker Hub images:
  - `tanqt11/rustdesk-selfhost-qt-server:latest`
  - `tanqt11/rustdesk-selfhost-qt-api:latest`
- Removed GHCR publishing from the workflow after registry instability and Docker Hub-only deployment was chosen.

### Admin Split and Server Key Management

- Added optional private admin split mode on port `21124`.
- Kept public API/Web v3 on port `21114`.
- Added optional admin restart override with Docker socket access for private admin deployments.
- Added admin server keypair actions:
  - load mounted server public key;
  - generate a new Ed25519 server keypair;
  - import matching public/private keypair;
  - restart the `rustdesk-server` container when the restart override is enabled.
- Clarified that RustDesk clients use only the public key; the private key stays server-side and is only needed for import/rotation.

### Web v3 Connection Fixes

- Fixed Web v3 endpoint seeding so the browser uses reachable WebSocket entrypoints instead of container-internal hosts.
- Fixed the native-port/WebSocket-port mismatch:
  - localStorage stores native ports `21116/21117`;
  - the legacy web protocol internally connects to `21118/21119`.
- Fixed current-host Web v3 behavior for Tailscale/private admin access.
- Fixed relay WebSocket selection so a browser session opened through `100.70.7.104:21124` keeps relay traffic on `100.70.7.104:21119`, even if hbbs returns a public DNS relay.
- Bumped Web v3 build marker to `20260521-relay-entry1`.
- User confirmed the Web v3 connection works after this fix.

### Known Remaining Gaps

- Web v3 video rendering can still show browser-only color artifacts or protected-video black screens; native RustDesk clients remain the stable path.
- Custom client package generation is an MVP for config/deployment output, not a full branded binary builder yet.
- Admin UI is usable but still needs polish for devices, users, settings, OAuth, and operational workflows.
