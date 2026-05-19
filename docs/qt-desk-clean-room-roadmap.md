# QT Desk Clean-Room Roadmap

Last updated: 2026-05-16

## Direction

QT Desk should become a clean, open-source remote access platform instead of a permanently RustDesk-branded fork.

This means:

- Original QT Desk brand, UI, docs, icons, and product wording.
- A documented QT Desk protocol.
- A QT Desk control plane.
- A QT Desk relay/rendezvous server.
- QT Desk desktop/mobile clients.
- Compatibility bridges only where legally safe and clearly attributed.

## Reality Check

This is not a small rebrand task. RustDesk-level remote desktop includes:

- NAT traversal and relay.
- Auth, device identity, server keys, users, groups, and policies.
- Capture pipeline per OS.
- Input injection per OS.
- Video encoding/decoding.
- Low-latency transport and congestion handling.
- Clipboard/file transfer/audio/multi-monitor.
- Installers, signing, auto-update, crash diagnostics, and mobile clients.

The safe strategy is to ship useful QT Desk-owned slices while replacing RustDesk-derived pieces over phases.

## OpenViking Role

OpenViking is a context database for AI agents, not a remote desktop protocol or media engine.

Use it for:

- Long-term project memory.
- Architecture decisions.
- Clean-room documentation.
- Feature/spec retrieval.
- Build/release runbooks.
- Security review notes.
- Mapping which files are derived, rewritten, or original.

Do not use it for:

- Screen capture.
- Video transport.
- NAT traversal.
- Input injection.
- Replacing the relay server.

## Legal Hygiene Model

### Derived Track

Existing RustDesk/RustDesk-server-derived code remains in a clearly marked derived folder and keeps upstream notices/licenses.

Use only for:

- Compatibility testing.
- Migration path.
- Temporary production while QT Desk-native pieces are built.

### Clean-Room Track

New QT Desk-native code goes into fresh modules with:

- Original design docs.
- Original implementation notes.
- No copied RustDesk code.
- No copied Pro generator code.
- No RustDesk logos/names/icons.

### Documentation

Before public release, add:

- `NOTICE.md`
- `TRADEMARKS.md`
- `LICENSES/`
- source availability notes for AGPL-derived binaries/services.

## Architecture Target

### Control Plane

Existing `rustdesk-api` becomes `qt-desk-control` over time.

Responsibilities:

- Users and teams.
- Devices.
- Device groups.
- Policies.
- OAuth/OIDC/2FA.
- Custom client builder.
- Audit logs.
- Backup/restore.
- Session broker.

### Rendezvous And Relay

New QT Desk server components:

- `qtdesk-id`: device registration, presence, NAT negotiation.
- `qtdesk-relay`: authenticated relay transport.
- `qtdesk-session`: session authorization and policy enforcement.

First target can keep WebSocket/TCP relay simple, then add UDP/WebRTC later.

### Client

New QT Desk client:

- `qtdesk-client-core`
- `qtdesk-client-windows`
- `qtdesk-client-macos`
- `qtdesk-client-linux`
- `qtdesk-client-android` later

The first native client should be Windows-only because the current user environment and testing loop are Windows-first.

### Web Client

Existing Web v3 work becomes the first QT Desk-native client surface:

- Browser UI already original.
- Replace old RustDesk protocol bundle with QT Desk-native transport.
- Add WebCodecs/WebRTC path for modern browsers.

## Protocol Plan

### QTDP v0

Simple, owned MVP protocol.

- WebSocket over TLS.
- Server-issued short-lived session token.
- Binary frame channel.
- JSON control channel.
- H.264/VP8/AV1 frame payload option where encoder exists.
- RGBA/JPEG fallback for MVP only.
- Mouse/keyboard input messages.
- Heartbeat, reconnect, quality hints.

### QTDP v1

Production protocol.

- QUIC/WebTransport or WebRTC data channels where feasible.
- Adaptive bitrate.
- Multi-monitor stream negotiation.
- Clipboard/file transfer channels.
- Per-channel permissions.
- Relay-assisted NAT traversal.

## Implementation Phases

### Phase 0: Project Split

- Rename top-level docs to QT Desk.
- Add legal/notice/trademark files.
- Mark existing RustDesk-derived directories.
- Add `docs/qt-desk-clean-room-roadmap.md`.
- Add an `architecture/decisions` folder.

### Phase 1: OpenViking Memory Layer

- Add optional `openviking` service to Docker Compose.
- Add `docs/openviking-memory-map.md`.
- Store:
  - architecture decisions
  - issue history
  - protocol drafts
  - release notes
  - clean-room file map
- Keep OpenViking optional; QT Desk must run without it.

### Phase 2: QT Desk Protocol Spec

- Create `docs/qtdp-v0.md`.
- Define auth handshake.
- Define frame format.
- Define input messages.
- Define reconnect/error codes.
- Define audit events.

### Phase 3: Web v3 Native Transport Prototype

- Add a new `/qtdp/ws` backend endpoint.
- Add browser WebSocket client in `/web3/`.
- Stream a synthetic desktop test pattern first.
- Then stream real captured frames from a local Windows agent.
- Keep RustDesk bundle as compatibility mode during transition.

### Phase 4: Windows Agent MVP

- New `qtdesk-agent-windows`.
- Capture screen using Windows Graphics Capture or DXGI Desktop Duplication.
- Encode with Media Foundation where possible.
- Inject input using Windows SendInput.
- Register with control plane.
- Enforce policy locally.

### Phase 5: Relay And Session Broker

- Build `qtdesk-relay`.
- Device connects outbound to relay.
- Browser/admin connects to relay with session token.
- Relay never accepts unauthenticated device control.

### Phase 6: Custom Client Builder

- Generate QT Desk Windows agent installer.
- Preconfigure:
  - server URL
  - public key
  - connection mode
  - policy lock
  - company name/icon
- Later add macOS/Linux.

### Phase 7: Replace Remaining Derived Runtime Pieces

- Remove dependency on old RustDesk web protocol bundle.
- Replace derived server where still used.
- Keep compatibility connector as optional and clearly attributed.

## First Concrete Tasks

1. Add legal files:
   - `NOTICE.md`
   - `TRADEMARKS.md`
   - `docs/derived-code-map.md`
2. Add OpenViking optional service design.
3. Draft QTDP v0 protocol.
4. Add a native WebSocket demo stream endpoint that serves a generated moving test pattern.
5. Make Web v3 switchable:
   - compatibility mode: current RustDesk bridge
   - native mode: QTDP v0 test stream

## Success Criteria

QT Desk starts becoming independent when:

- `/web3/` can render a QTDP native stream without loading `/webclient/js/dist/index.js`.
- A Windows QT Desk agent can register and stream a real desktop to Web v3 through QT Desk relay.
- Admin can issue and revoke QT Desk-native session tokens.
- Public repo clearly separates derived and original code.
