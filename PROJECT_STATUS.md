# QT-DESK Project Status

Last updated: 2026-05-21

Use this file as the handoff anchor for future prompts. At the start of a new session, ask Codex to read `PROJECT_STATUS.md` first, then continue from the open items.

## Current Goal

Build and maintain a private RustDesk self-host stack based on forks of:

- `lejianwen/rustdesk-api`
- `lejianwen/rustdesk-server` on the `forapi` branch

Primary goals:

- Keep RustDesk clients 1.4.1+ compatible when users are logged in through the API.
- Split server and API into separate Docker services.
- Provide a professional admin dashboard.
- Restore a usable WebClient path, then replace it with a self-owned Web v3 implementation.
- Make backup, restore, server key export/import, and deployment easy.
- Add a legally safe QT Desk custom-client builder/rebrand path.

## Overall Progress

Current practical completion estimate: 88%.

Meaning:

- Core RustDesk self-host compatibility: 90%.
- Docker split deployment and admin/API split: 92%.
- Backup, restore, and old-server migration: 86%.
- Admin usability/polish: 78%.
- Public GitHub readiness: 88%.
- Production self-host docs: 86%.
- Web v3 remote-control stability: 78%.
- Custom client builder/rebrand pipeline: 45%.
- Clean-room QT Desk-native direction: 15%.

The project is usable for VPS/private self-host testing as a RustDesk-compatible control plane, but not yet "finished" as a polished QT Desk product. Main remaining product risks are Web v3 video/DRM/tearing behavior, custom client binary builds, and deeper admin UI polish.

## Latest VPS/Web v3 Status

Status: working on 2026-05-21.

- GitHub root repo: `tanqt0728/qtdesk`.
- Docker Hub images:
  - `tanqt11/rustdesk-selfhost-qt-server:latest`
  - `tanqt11/rustdesk-selfhost-qt-api:latest`
- VPS private admin/Web v3 test target:
  - Admin: `http://100.70.7.104:21124/_admin/`
  - Web v3: `http://100.70.7.104:21124/web3/`
- User confirmed Web v3 connection works after the relay-entrypoint fix.
- Important Web v3 behavior:
  - Native RustDesk clients use native ports `21116/21117`.
  - Web v3 browser sessions use WebSocket ports `21118/21119`.
  - The legacy web protocol stores native ports in `localStorage` and internally adds `+2` for WebSocket.
  - Do not seed `21118/21119` directly into `custom-rendezvous-server` / `custom-relay-server`; that causes accidental `21120/21121`.
- Current Web v3 build marker: `20260521-relay-entry1`.
- Latest Web v3 connection fixes:
  - browser-facing config now prefers the current request host for non-localhost Web v3 entrypoints;
  - frontend now prefers `rendezvous_ws_server` / `relay_ws_server` when seeding protocol localStorage;
  - relay WebSocket connections are rewritten to the selected Web v3 entrypoint, so a session opened through Tailscale does not get pulled back to a public DNS relay returned by hbbs.
- Expected browser console in Tailscale admin mode:
  - `Connecting to rendezvoous server: ws://100.70.7.104:21118`
  - `Connecting to relay server: ws://100.70.7.104:21119`
- If a browser still shows `20260519-input-layer1`, the VPS image or browser cache is stale.

Current live Web v3 blocker:

- Browser-rendered remote images can still show color corruption/tearing in Web v3 while the native RustDesk client renders the same remote desktop correctly.
- This points at the legacy WebClient browser decoder/render path, especially VP9/YUV-to-RGBA/readback behavior, not the RustDesk server stream itself.
- Do not keep adding random UI toggles for this. `20260518-yuv-software1` made the browser-rendered image worse for the user and was rolled back to `20260518-yuv-rollback1`.
- User confirmed on 2026-05-19 that `20260518-yuv-rollback1` still shows visible colored block artifacts after connection, especially on browser content. This confirms the old embedded WebClient render path is not stable enough for the product's main web remote-control experience.
- Current engineering decision: fix concrete Web v3 layering bugs, but stop treating the embedded legacy WebClient VP9/WASM/YUV renderer as the final stable product path. Keep it as a compatibility/experimental path while planning the reliable Web path around either a proven gateway protocol (Guacamole/RDP/VNC/noVNC) or a new WebRTC/WebCodecs media pipeline.

## Latest Runtime Config

Status: done on 2026-05-18.

- Server public host is centralized in `.env` as `QT_DESK_SERVER_HOST=<server-ip-or-dns>`.
- `RUSTDESK_ID_PUBLIC`, `RUSTDESK_RELAY_PUBLIC`, and `RUSTDESK_API_PUBLIC_URL` are derived from that one host value.
- Docker Compose config expands the derived values to `<server-ip-or-dns>:21116`, `<server-ip-or-dns>:21117`, and `http://<server-ip-or-dns>:21114`.
- `rustdesk-server` and `rustdesk-api` were force-recreated with the new environment.
- Verification:
  - `GET http://127.0.0.1:21114/api/web-v3/config` returns the configured rendezvous/relay host.
  - `GET http://127.0.0.1:21114/web3/` returns HTTP 200.
  - Public `GET http://127.0.0.1:21114/_admin/` returns HTTP 404.
  - Private `GET http://127.0.0.1:21124/_admin/` returns HTTP 200.
- Older `192.168.88.10` entries below are historical test notes, not the current target host.
- If the configured host is in the `100.x.x.x` private/CGNAT-style range, it is expected to work for VPN/Tailscale/private-network clients, not arbitrary public internet users.

## Latest VPS/GitHub Readiness Check

Status: ready for private/VPS trial on 2026-05-19.

- Current recommendation:
  - OK to push to GitHub and deploy to a VPS for self-host testing.
  - Treat Web v3 as experimental until the video renderer is replaced or a Guacamole/noVNC/WebRTC/WebCodecs path is added.
  - Use native RustDesk/QT custom clients as the stable remote-control path.
- Local Docker status:
  - `rustdesk-server` is running and healthy.
  - `rustdesk-api` is running.
  - Public API/Web v3 is on `21114`.
  - Admin split is active on `127.0.0.1:21124`.
- Public-readiness scan:
  - `tools/check-public-ready.ps1` passed.
  - Required publication files are present.
  - `.env` and secret/key/database/archive patterns are ignored.
  - No high-confidence secret patterns were found in publishable files.
- VPS caution:
  - Private/VPN-style addresses such as `100.x.x.x` are not public internet addresses. For an internet VPS, replace `QT_DESK_SERVER_HOST` with the VPS public IP or DNS name.
  - Do not expose `21124` directly to the internet. Access admin through SSH tunnel, VPN, or reverse proxy with allowlist/auth.

## Latest Web v3 Rendering Reset

Status: done on 2026-05-18.

- Web v3 build marker is now `20260518-render-reset1`.
- Default renderer no longer forces the legacy CPU YUV conversion path. That forced path made the browser-only color/washed-out rendering issue worse on some remote browser windows.
- On first load of this build, old local `Direct YUV` and `Video boost` settings are cleared automatically, and the default mode is reset to `Balanced / 30 FPS`.
- Mouse wheel handling was corrected:
  - scroll direction no longer flips sign;
  - wheel threshold increased from `40` to `80`;
  - each flush sends at most one wheel step, so scrolling is less jumpy.
- `rustdesk-api` image was rebuilt and the API container was force-recreated.
- Verification:
  - `/web3/` serves `app.js?v=20260518-render-reset1`.
  - Chrome CDP smoke test loaded Web v3, opened the menu, toggled Monitor, and confirmed Monitor text shows `Quality Balanced`.
  - `/api/web-v3/config` still returns the configured rendezvous/relay host.

## Latest Web v3 Keyboard Fix

Status: done on 2026-05-18.

- Web v3 build marker is now `20260518-keyboard1`.
- Fixed 100%-repro double typing where one physical key press could produce two remote characters.
- Root cause: Web v3 sent a key event on `keydown`, then sent `press:true` again on `keyup`.
- New behavior:
  - printable characters send exactly one `input_string` on `keydown`;
  - function/control keys send normal `input_key` down/up with `press:false`;
  - repeated control-key `keydown` is ignored while the key is already active;
  - browser `blur` clears active key state to avoid stuck keys.
- `rustdesk-api` image was rebuilt and the API container was force-recreated.
- Verification:
  - `/web3/` serves `app.js?v=20260518-keyboard1`.
  - Served `app.js` contains `input_string`, `activeKeys`, `press: "false"`, and the `blur` active-key reset.

## Latest Web v3 YUV/Wheel Correction

Status: deployed on 2026-05-18.

- Web v3 build marker is now `20260518-yuv-wheel1`.
- Mouse wheel direction was restored to the behavior that previously matched user testing:
  - `consumeWheelSteps()` returns `-sign * steps`;
  - wheel flush threshold is consistently `80`, not a mixed `40/80`.
- Direct YUV is now the default renderer:
  - default `directYuv` is `true`;
  - first load of this build forces saved `directYuv` back to `true`;
  - `videoCompatibility` is still reset to `false`.
- Rationale:
  - the visible issue is image corruption/tearing, not keyboard;
  - native RustDesk client renders correctly, so the server stream is likely OK;
  - defaulting to Direct YUV tries to bypass the legacy WebClient RGBA readback path that produced browser-window corruption.
- Verification:
  - `GET http://127.0.0.1:21114/web3/` serves `app.js?v=20260518-yuv-wheel1`.
  - `GET http://127.0.0.1:21124/web3/` serves `app.js?v=20260518-yuv-wheel1`.
  - Served `app.js` contains `directYuv: true`, `return -sign * steps`, keyboard `input_string`, and `blur` active-key reset.
- If this build still shows browser color corruption, the next step is not more settings UI. Investigate replacing the embedded WebClient VP9/YUV rendering path with a direct visible renderer/WebCodecs path.

## Latest Web v3 Software YUV Renderer

Status: rolled back on 2026-05-18.

- Web v3 build marker is now `20260518-yuv-software1`.
- Direct YUV is still the default, but the visible YUV renderer now forces `YUVCanvas.attach(..., { webGL: false })`.
- Rationale:
  - user observed browser-window artifacts that are clean at first and gradually appear over time;
  - that pattern points to WebGL texture/frame-sink accumulation or stale GPU composition, not an immediate stream/color-matrix problem;
  - forcing software canvas keeps the RGBA readback bypass while removing the browser WebGL visible renderer from the path.
- Monitor and Diagnostics now label the active path:
  - `YUV SW` means software Direct YUV is active;
  - `YUV GL` means software failed and WebGL fallback was used.
- Mouse wheel direction remains at the last user-tested-good behavior:
  - `consumeWheelSteps()` returns `-sign * steps`.
- Verification:
  - `GET http://127.0.0.1:21114/web3/` serves `app.js?v=20260518-yuv-software1`.
  - `GET http://127.0.0.1:21124/web3/` serves `app.js?v=20260518-yuv-software1`.
  - Served `app.js` contains `webGL: false`, `YUV SW`, `Direct YUV visible renderer using software canvas`, and `return -sign * steps`.
  - Public `GET http://127.0.0.1:21114/_admin/` returns `404`.
  - Private `GET http://127.0.0.1:21124/_admin/` returns `200`.
  - `GET http://127.0.0.1:21114/api/web-v3/config` returns the configured ID and relay endpoints.
- If this still slowly corrupts, stop changing surface UI. Next step is to add renderer recreation on a timer/frame threshold, then test WebCodecs or a Rust/WASM decoder bridge.

## Latest Web v3 Rendering Rollback And Architecture Decision

Status: deployed on 2026-05-18.

- Web v3 build marker is now `20260518-yuv-rollback1`.
- The forced software Direct YUV renderer from `20260518-yuv-software1` was removed because user testing showed the image became worse.
- Direct YUV now uses automatic `YUVCanvas.WebGLFrameSink.isAvailable()` detection again:
  - `YUV GL` means browser WebGL Direct YUV is active;
  - `YUV SW` means the browser could not use WebGL and fell back to software.
- Decision:
  - Native RustDesk client renders the same remote desktop correctly.
  - Web v3 corruption is therefore isolated to the browser WebClient decode/render path, not the server stream.
  - Do not keep chasing this with more small renderer toggles.
- Best-practice architecture direction:
  - Short-term reliable web access: integrate a proven browser gateway such as Apache Guacamole for RDP/VNC/SSH, or noVNC for VNC targets.
  - Long-term QT Desk web-native path: build a new WebRTC media transport plus browser-native WebCodecs decode path, with input over WebRTC data channel or a dedicated low-latency control channel.
  - Keep RustDesk native client/custom client as the high-quality default for full remote-control use.
- Verification:
  - `GET http://127.0.0.1:21124/web3/` serves `app.js?v=20260518-yuv-rollback1`.
  - Served `app.js` contains `Direct YUV visible renderer using`, `WebGLFrameSink`, `YUV GL`, and `return -sign * steps`.
- Follow-up user test on 2026-05-19:
  - Web v3 connects and displays the remote desktop.
  - Visible colored block artifacts still appear over remote browser content.
  - Treat Web v3 as experimental until the video path is replaced.

## Latest Web v3 Input Layer Isolation

Status: deployed on 2026-05-19.

- Web v3 build marker is now `20260519-input-layer1`.
- Concrete code bug/risk fixed:
  - in Direct YUV mode, the visible video is rendered by `#remoteVideoCanvas`;
  - `#remoteCanvas` is only needed as the input/focus layer;
  - previously `#remoteCanvas` sat above the video and could visually overlay stale RGBA pixels even when Direct YUV was active;
  - now `.stage.direct-yuv #remoteCanvas` has `opacity: 0`, so it still receives mouse/keyboard focus but cannot visually contaminate the video layer.
- This is closer to the standard browser remote-control pattern: separate the media display layer from the transparent input capture layer.
- `rustdesk-api` image was rebuilt and the API container was force-recreated.
- Verification:
  - `GET http://127.0.0.1:21124/web3/` serves `app.js?v=20260519-input-layer1`.
  - Served CSS contains `.stage.direct-yuv #remoteCanvas` with `opacity: 0`.
  - Public `GET http://127.0.0.1:21114/_admin/` returns `404`.
  - Private `GET http://127.0.0.1:21124/_admin/` returns `200`.
- If colored blocks remain after this build, the remaining issue is very likely inside the old VP9 decode/YUV renderer itself or remote-browser GPU capture, not the Web v3 canvas layering.

## Repository Layout

- `rustdesk-server`: forked server code, patched for API/JWT login compatibility.
- `rustdesk-api`: forked API/admin/WebClient code currently used by Docker.
- `rustdesk-api-v2`: local reference copy checked for old WebClient v2 traces.
- `docker-compose.yml`: Linux/server compose.
- `docker-compose.windows.yml`: Windows Docker Desktop override.
- `.env`: local runtime config and secrets. Do not publish this file.
- `.env.example`: safe example config.

## Completed Work

### Core RustDesk Client Fix

Status: done and user-tested.

- RustDesk 1.4.6 clients were tested on two computers.
- API login + remote connection now works.
- Direct ID/password connection also continues to work.
- Server logs showed API JWT punch requests accepted after token normalization.

Changed areas:

- `rustdesk-server/Cargo.toml`
- `rustdesk-server/Cargo.lock`
- `rustdesk-server/src/jwt.rs`
- `rustdesk-server/src/relay_server.rs`
- `rustdesk-server/src/rendezvous_server.rs`
- `rustdesk-server/Dockerfile`

Main fixes:

- Bumped server version metadata to 1.1.15.
- Normalized JWT tokens by trimming whitespace and stripping `Bearer `.
- Removed secret logging.
- Added targeted auth diagnostics around API punch requests.
- Kept hbbs/hbbr in a separate server container.

### Docker Split Deployment

Status: done locally.

- `rustdesk-server` and `rustdesk-api` run as separate Docker Compose services.
- Windows Docker Desktop override maps required ports instead of using host networking.
- API and server images build locally:
  - `tanqt0728/rustdesk-server-s6-fixed:local`
  - `tanqt0728/rustdesk-api-fixed:local`

Current local services:

- `rustdesk-server`: hbbs/hbbr, healthy, ports 21115-21119 TCP and 21116 UDP.
- `rustdesk-api`: public API/Web v3 on port 21114; private admin/API on `127.0.0.1:21124` through `docker-compose.admin-split.yml`.

### API Backend Fixes

Status: partially done.

Changed areas:

- `rustdesk-api/Dockerfile`
- `rustdesk-api/service/user.go`
- `rustdesk-api/http/controller/web/index.go`
- `rustdesk-api/http/router/admin.go`
- `rustdesk-api/http/controller/admin/backup.go`
- `rustdesk-api/.gitignore`

Main fixes:

- API Dockerfile now builds from local source instead of copying release binaries.
- Login log bug fixed: user token log now stores the token ID correctly.
- WebClient config now uses same-origin API URL to avoid `127.0.0.1` vs LAN CORS/fetch failures.
- Admin `rustdesk/sendCmd` is protected by admin privilege middleware.
- Backup export/import endpoint added.
- `resources/admin` is now tracked.

### Backup And Restore

Status: implemented, needs authenticated export/import testing with the current admin password.

Full backup export includes:

- API SQLite DB: `/app/data/rustdeskapi.db`
- API config: `/app/conf/config.yaml`
- Server key: `/server-data/id_ed25519`
- Server public key: `/server-data/id_ed25519.pub`

Import restores the same files and returns a restart-required response.

Important: after importing server keys, restart both `rustdesk-server` and `rustdesk-api`.

Component backup/restore now supports:

- raw database
- API config
- server keypair
- users, password hashes, groups, OAuth providers, and OAuth account links
- address book entries, saved remote passwords, collections, rules, and tags
- devices
- logs/audit records

Smart import:

- The admin Backup page has an `Inspect backup` action that previews manifest status, detected components, countable records, file list, sensitive-data warning, and restart requirement without restoring anything.
- The admin Backup page has a `Smart import` action.
- Every import path now runs an inspect preflight before writing data.
- Risky imports show a final browser confirmation when the backup contains sensitive data, config, server keys, raw database, or will require restart.
- Smart import posts to the selective restore endpoint without a manual component list.
- The backend reads `manifest.json` when present; if no manifest exists, it restores the recognizable files in the zip.
- Restart is only requested when raw database, config, or server keys were actually restored.
- Smart import recognizes common raw/SFTP backup zip layouts:
  - `rustdeskapi.db`
  - `data/rustdeskapi.db`
  - `app/data/rustdeskapi.db`
  - `config.yaml`
  - `conf/config.yaml`
  - `app/conf/config.yaml`
  - `server/id_ed25519`
  - `server/id_ed25519.pub`
  - `server-data/id_ed25519`
  - `server-data/id_ed25519.pub`

Migration helper:

- `tools/export-legacy-rustdesk-api.py` reads an old `lejianwen/rustdesk-api` SQLite `rustdeskapi.db` and creates a selective backup zip that the new admin UI can import.
- `tools/pack-sftp-backup.py` packs files copied by SFTP into a standard importable zip for old deployments that had no backup export endpoint.
- Typical old-to-new migration command:

```sh
python tools/export-legacy-rustdesk-api.py --db /path/to/old/rustdeskapi.db --out rustdesk-legacy-selected-backup.zip --components users,address_book,devices
```

Typical raw/SFTP file backup packing command:

```sh
python tools/pack-sftp-backup.py --root /path/to/sftp-copy --out rustdesk-sftp-backup.zip
```

Verification:

- `docker compose --env-file .env -f docker-compose.yml -f docker-compose.windows.yml -f docker-compose.admin-split.yml build rustdesk-api` passed after adding selective backup.
- Rebuilt and restarted `rustdesk-api` after adding inspect preflight and risky-import confirmation.
- Split mode still keeps public `21114` admin routes unavailable while private `21124` serves the admin UI.
- `http://127.0.0.1:21114/_admin/` returns 404.
- `http://127.0.0.1:21114/api/web-v3/config` returns 200.
- `http://127.0.0.1:21124/_admin/` returns 200 and contains `Inspect backup` and `Smart import`.
- Unauthenticated `POST /api/admin/backup/inspect` returns a `403` JSON response.
- Rebuilt and restarted `rustdesk-api` after raw/SFTP backup path compatibility and `tools/pack-sftp-backup.py`.
- `tools/check-public-ready.ps1` passes.

### Admin Dashboard

Status: improved, but not final.

Changed areas:

- `rustdesk-api/resources/admin/index.html`
- `rustdesk-api/resources/admin/styles.css`
- `rustdesk-api/resources/admin/app.js`

Current admin features:

- Cleaner sidebar:
  - Dashboard
  - Devices
  - Address Book
  - Web Access
  - Users
  - Logs
  - Settings
  - Backup
- Dashboard now has a clearer control-console layout:
  - live overview hero
  - health/readiness checklist for API, ID server, relay, public key, and Web v3
  - quick action cards for Web v3, Devices, Login/OAuth, and Backup
  - server config moved into a dedicated compact panel
- Added a dedicated Web Access page:
  - Web v3 status summary
  - active session/open share counters when admin data is available
  - shortcuts to Web v3 Sessions, Shares, Audit, and device selection
  - one-click stale session cleanup for dead browser sessions
  - policy snapshot for permissions, clipboard, and file-transfer defaults
  - connection endpoint summary using `/api/web-v3/config`
- Device rows show:
  - Open App
  - WebClient
  - Share Link
  - Copy
  - Save AB
- User CRUD now uses real form fields instead of raw JSON only.
- User password change action exists.
- OAuth/WebAuth management form uses actual backend fields:
  - `oauth_type`
  - `op`
  - `issuer`
  - `scopes`
  - `client_id`
  - `client_secret`
  - `auto_register`
  - `pkce_enable`
  - `pkce_method`
- Login page can show OAuth provider buttons from `/api/admin/login-options`.
- Logs page has shortcuts for connection, login, file, and share records.
- Settings has advanced shortcuts for profile, OAuth/WebAuth, groups, device groups, and server commands.
- Settings now has a Web v3 policy editor for:
  - enable/disable Web v3
  - default share expiry
  - max session duration
  - clipboard/file-transfer/terminal policy flags
  - direct-mode login requirement
  - anonymous share-link access
  - default browser-session permissions
- Added a Deployment page:
  - shows public API/Web v3, private admin, ID server, and relay server endpoints
  - includes an admin-split readiness checklist
  - explains safe public/private exposure
  - provides copyable Docker Compose, SSH tunnel, public readiness check, and image env commands
  - links backup and custom-client workflows from the deployment screen

Known admin gaps:

- Some pages still use generic table rendering.
- Need dedicated polished pages for Users, Devices, Address Book, Logs, OAuth, Backup, and Web v3 settings persistence.
- Need richer filters, pagination, detail drawer, and safer confirmation dialogs.
- Need browser testing for create/update/delete flows with current credentials.
- Logged-in admin UI still needs a real browser pass with the current admin password; unauthenticated layout and served assets were smoke-tested.

Latest deployment-page verification:

- Rebuilt and restarted `rustdesk-api`.
- `http://127.0.0.1:21114/_admin/` returns 404.
- `http://127.0.0.1:21114/api/web-v3/config` returns 200.
- `http://127.0.0.1:21114/web3/` returns 200.
- `http://127.0.0.1:21124/_admin/` returns 200 and contains `deploymentView` / `deploySplitCommand`.
- `http://127.0.0.1:21124/_admin/app.js` returns 200 and contains `renderDeployment` / `data-copy-deploy`.
- `tools/check-public-ready.ps1` passes.

Latest Web v3 settings persistence verification:

- Added `model.WebV3Settings` and bumped database version to 267.
- Admin `GET/POST /api/admin/web-v3/settings` now read/write persisted DB policy instead of returning `persisted:false`.
- Public `/api/web-v3/config` now uses persisted Web v3 enabled state, default permissions, and max session seconds.
- New Web v3 sessions and shares now use persisted session duration, default share expiry, and default permissions.
- Selective backup `config` component now includes `data/web_v3_settings.json`; smart import can restore it.
- Rebuilt and restarted `rustdesk-api`; logs show `Migrating....267`.
- `http://127.0.0.1:21114/api/web-v3/config` returns 200 with Web v3 policy fields.
- Unauthenticated private admin POST to `/api/admin/web-v3/settings` returns JSON `code:403`.

Latest Web v3 stale-session cleanup verification:

- Added admin `POST /api/admin/web-v3/session/cleanup`.
- Added Web Access `Clean stale` action card.
- Cleanup marks expired or older-than-5-minutes sessions disconnected/revoked so the Active sessions count does not keep growing after browser disconnects.
- `/_admin/` contains `webV3CleanupSessionsBtn`; `/_admin/app.js` contains `cleanupWebV3Sessions`.
- Unauthenticated cleanup POST returns JSON `code:403`.
- Public `21114` still returns 404 for `/_admin/`.
- `tools/check-public-ready.ps1` passes.

Latest Web v3 entry-screen verification:

- `/web3/` now has a real connection entry screen:
  - remote ID input
  - remote password input
  - public `/api/login` sign-in
  - authenticated `/api/peers` device list
  - click a device to fill the remote ID
- Existing URL modes still work:
  - `/web3/#/?id=<peer_id>`
  - `/web3/#/?share_token=<token>`
  - `/web3/#/?session_id=<session_id>`
- Direct ID mode uses the Web v3 login token stored under the public `21114` origin, so it no longer depends on private-admin `21124` localStorage.
- Rebuilt and restarted `rustdesk-api`.
- `http://127.0.0.1:21114/web3/` returns 200 and contains `connectPeerId`, `loginUsername`, and `deviceList`.
- `http://127.0.0.1:21114/web3/app.js` returns 200 and contains `loginWeb3`, `/api/peers`, and `connectPeerId`.
- `http://127.0.0.1:21114/web3/styles.css` returns 200 and contains the login/device-list styles.
- `http://127.0.0.1:21114/api/web-v3/config` returns 200.
- `http://127.0.0.1:21124/_admin/` returns 200.
- `http://127.0.0.1:21114/_admin/` returns 404.

Latest Web v3 flow hardening:

- Added a Web v3 sign-out button and visible login state so login feels immediate instead of only appearing after refresh.
- The Web v3 public login token is stored under the public `21114` origin and can be cleared from the Web v3 screen.
- Added `stopTransportAndReturn` so Disconnect / Connection screen cancels reconnect timers, marks the action as manual, and prevents delayed socket-close handlers from restarting retry.
- Added retry-race guard inside delayed reconnect callbacks.
- Added API device metadata for Web v3 device lists:
  - `last_online_ip`
  - `last_online_time`
  - `same_client_ip`
- Correction: IP-based self-control blocking was removed because all devices behind the same LAN/NAT can share the browser client IP.
- Device choices now show `Same network/IP as this browser` as informational metadata only; it does not mark devices red and does not block connecting.
- Important residual limitation: pure browser Web v3 cannot know the local RustDesk ID with 100% certainty. Strong self-control prevention needs a native helper/client handshake or a user/device-side policy that marks the local device as not connectable from the same host.

Latest self-control false-positive fix:

- Removed `shouldBlockSelfControl`.
- Removed `block_self_control`.
- Removed red `device-choice.danger` UI.
- Rebuilt and restarted `rustdesk-api`.
- `http://127.0.0.1:21114/web3/app.js` returns 200 and no longer contains `Likely this browser`, `Self-control blocked`, or `shouldBlockSelfControl`.
- `http://127.0.0.1:21114/web3/styles.css` returns 200 and no longer contains `device-choice.danger`.
- `http://127.0.0.1:21114/web3/` returns 200.
- `http://127.0.0.1:21114/_admin/` returns 404.

Latest fullscreen aspect-ratio fix:

- Fixed Web v3 fullscreen/adaptive scaling so the remote canvas keeps the remote aspect ratio instead of stretching to `100vw x 100vh`.
- Default/adaptive mode now computes `--canvas-fit-width` and `--canvas-fit-height` in JS and centers the canvas.
- `Stretch` mode remains available and is now the only mode that intentionally fills both width and height.
- `Original` mode keeps intrinsic canvas size.
- Fullscreen changes, window resize, and visual viewport resize now call `applyCanvasAspect`.
- Rebuilt and restarted `rustdesk-api`.
- `http://127.0.0.1:21114/web3/styles.css` returns 200 and contains `--canvas-fit-width`, centered transform, and stretch-mode override.
- `http://127.0.0.1:21114/web3/app.js` returns 200 and contains `applyCanvasAspect` / `--canvas-fit-width`.
- `http://127.0.0.1:21114/web3/` returns 200.
- `http://127.0.0.1:21114/_admin/` returns 404.

Latest Web v3 retry hardening:

- Fixed repeated remote accept/cancel popups caused by auto-reconnect during pre-auth/pre-frame connection attempts.
- Added `stableConnection`; Web v3 only considers a connection stable after a remote frame is rendered.
- `connection_ready` / relay secured / anonymous msgbox events now show handshake progress but do not mark the session as connected.
- Automatic reconnect is allowed only when:
  - a remote frame has rendered at least once
  - the session is marked stable
  - no password prompt is pending
  - the user did not manually disconnect
- Remote cancel/reject/denied/refused/permission-style errors now return to the connection screen and explicitly do not retry.
- Manual disconnect and Connection screen cancel delayed command retries too.
- Rebuilt and restarted `rustdesk-api`.
- `http://127.0.0.1:21114/web3/app.js` returns 200 and contains `stableConnection`, `canAutoReconnect`, `Handshake complete`, and the no-auto-retry copy.
- `http://127.0.0.1:21114/web3/` returns 200.
- `http://127.0.0.1:21114/_admin/` returns 404.

Latest Web v3 stale-frame false alarm fix:

- Fixed `Remote image stopped updating` false positives after a visible remote image had already rendered.
- Existing rendered remote desktop frames are now allowed to remain static without opening the reconnect/connection-screen modal.
- If the image is unchanged for 30s after a rendered frame, Web v3 only updates status/capture diagnostics; it does not interrupt control.
- The blocking modal is now reserved for the case where frames are expected but no remote image ever renders.
- Black-frame diagnostics are also non-blocking now; they open diagnostics and keep the connection status instead of showing a transport modal.
- Rebuilt and restarted `rustdesk-api`.
- `http://127.0.0.1:21114/web3/app.js` returns 200 and no longer contains `Remote image stopped updating`; it contains `Remote image did not render`, `Remote image unchanged`, and the rendered-frame guard.
- `http://127.0.0.1:21114/web3/` returns 200.
- `http://127.0.0.1:21114/_admin/` returns 404.

Latest Web v3 cache and reconnect-loop fix:

- Added Web v3 build marker `20260517-stall4` so browser console can confirm the exact frontend bundle.
- Versioned `/web3/styles.css` and `/web3/app.js` asset URLs to force browsers off stale cached bundles.
- Added `Cache-Control: no-store, no-cache, must-revalidate, max-age=0` for `/web3` static responses.
- Added a startup cache cleanup script that unregisters stale `/web3` or legacy `/webclient` service workers and deletes matching browser caches.
- Removed the automatic reconnect path that sent the old protocol command `setByName("reconnect")`.
- Automatic reconnect now calls the Web v3 connection flow directly and only stays eligible if the current connection attempt has rendered a remote frame.
- This should stop the accept/cancel popup loop where a stale or unstable WebSocket kept reconnecting before a real remote image appeared.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `http://127.0.0.1:21114/web3/` returns 200 with `no-store`, `20260517-stall4`, and `qtDeskClearOldWebCaches`.
  - `http://127.0.0.1:21114/web3/app.js?v=20260517-stall4` returns 200 with `no-store`.
  - Served app.js contains `WEB3_BUILD = "20260517-stall4"` and the current-attempt frame guard.
  - Served app.js no longer contains `Remote image stopped updating`.
  - Served app.js no longer contains `sendProtocolCommand("reconnect"`.
  - `http://127.0.0.1:21114/_admin/` returns 404.
  - `http://127.0.0.1:21124/_admin/` returns 200.
  - `http://127.0.0.1:21114/api/web-v3/config` returns 200.

Latest Web v3 disconnect investigation:

- Investigated the repeated Web v3 relay close loop instead of treating it as only a cache issue.
- Server logs showed rendezvous auth accepted and relay pairing succeeded, so the failure was after the transport had already reached the paired relay stage.
- Found a likely frontend/protocol misuse: Web v3 called the reused legacy WebClient connection object's live option methods (`setImageQuality` / toggle options) immediately during connection startup.
- Those methods send RustDesk `Message` frames to whatever WebSocket the legacy connection currently owns; during early startup that socket can still be the rendezvous socket or an unfinished relay socket.
- That can produce `send on CONNECTING state`, protocol confusion, and relay/peer close loops.
- Changed Web v3 build to `20260517-stall6`.
- Connection startup now only installs draw hooks and writes local peer options; it no longer sends live quality/audio/clipboard/option messages during handshake.
- Live protocol setting sends are now guarded by `canSendLiveProtocolCommand`, which requires a stable connection and rendered remote frame.
- Added a Transport field to the Video help panel showing the last WebSocket close endpoint/code/clean state and close count.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 with `no-store`, build `20260517-stall6`, and the new transport diagnostic field.
  - `/web3/app.js?v=20260517-stall6` returns 200 with `no-store`.
  - Served app.js no longer contains `tuneProtocolConnection` or `applyProtocolBoolean`.
  - Served app.js contains `canSendLiveProtocolCommand` and `lastTransportClose`.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest Web v3 input/rendering fix:

- Investigated user-reported color artifacts, weak perceived quality, and broken mouse wheel scrolling.
- Fixed mouse wheel payloads: wheel events now send `deltaX`/`deltaY` as the protocol `x`/`y` values instead of incorrectly sending remote canvas coordinates.
- Added `Direct YUV` as an explicit menu toggle and made it off by default.
- Web v3 now defaults to the stable RGBA fallback renderer to avoid direct-YUV/WebGL color artifacts such as red/green striping.
- Direct YUV remains available as an opt-in performance/tearing experiment.
- Turning Direct YUV off during a session immediately switches the canvas back out of direct-YUV mode.
- Changed Web v3 build marker to `20260517-input-render1`.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 with `no-store`, build `20260517-input-render1`, and `directYuvToggle`.
  - `/web3/app.js?v=20260517-input-render1` returns 200 with `no-store`.
  - Served app.js contains `directYuv: false`, the Direct YUV guard, and wheel delta handling.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest browser-only color corruption handling:

- User confirmed color corruption happens mainly inside remote browser content while other apps look mostly OK.
- Root assessment: this is likely remote Windows/browser GPU composition capture corruption, not normal Web v3 canvas scaling or direct-YUV rendering.
- Strengthened `tools/windows-browser-capture-compat.ps1`:
  - added `-KillBrowsers`
  - disables Chrome, Edge, and Brave hardware acceleration via HKCU policy
  - also writes browser `Local State` `hardware_acceleration_mode_enabled=false`
  - optional `-DisableMpo` still sets Windows DWM `OverlayTestMode=5` when run as Administrator
  - `-Undo` restores browser Local State to hardware acceleration enabled where possible and removes policy/MPO values
- Web v3 Video help now labels the first action as `Copy color fix`.
- `Copy color fix` now copies a self-contained PowerShell command that can be pasted directly on the remote Windows PC; it no longer assumes the repo script exists on that machine.
- `Copy MPO fix` now copies a self-contained Administrator command for the DWM overlay fix.
- Updated `docs/browser-video-capture-compat.md` with the browser-color workflow.
- Changed Web v3 build marker to `20260517-browser-color1`.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - PowerShell parser check for `tools/windows-browser-capture-compat.ps1` passed.
  - `/web3/` returns 200 with `no-store`, build `20260517-browser-color1`, and `Copy color fix`.
  - `/web3/app.js?v=20260517-browser-color1` returns 200 with `no-store`.
  - Served app.js contains the self-contained browser color fix, `HardwareAccelerationModeEnabled`, and `OverlayTestMode`.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest Web v3 password and scroll fix:

- User reported that logged-in devices still asked for a remote password, scroll wheel jumped to top/bottom, and the browser tab was still loading stale `20260517-input-render1`.
- Clarified product behavior: API/account login authorizes device listing and Web v3 session creation, but the RustDesk remote-control protocol can still require the target device password or remote-side approval.
- Added address-book saved password prefill:
  - Web v3 calls authenticated `/api/ab` after login/device selection.
  - If the selected peer has an address-book `password`, the connection password field is filled automatically and queued for the protocol login.
  - If no saved password exists, Web v3 explains that the remote password or remote approval is still required.
  - Logging in after manually typing a remote ID now also checks and fills the saved address-book password without requiring refresh.
- Tightened mouse wheel payloads again:
  - wheel events send delta values, not canvas coordinates
  - wheel button state is blank for wheel events
  - wheel magnitude is clamped smaller to reduce accidental jump-to-top/bottom behavior
- Changed Web v3 build marker to `20260517-scroll-auth1`.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-scroll-auth1`.
  - `/web3/app.js?v=20260517-scroll-auth1` returns 200 and contains `WEB3_BUILD`, `prefillSavedRemotePassword`, and the reduced wheel clamp.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.
  - Docker compose shows `rustdesk-api` running with public `21114` and private-admin `127.0.0.1:21124`.
- Current disconnect evidence from `rustdesk-server` logs:
  - API auth is accepted and relay requests are paired.
  - Recent sessions closed after roughly 50 seconds to 4 minutes, so the current problem is a post-handshake relay/WebSocket close, not an initial ID/key/token rejection.
  - Browser must hard-refresh or open a new `/web3/` tab and confirm console build `20260517-scroll-auth1` before the next disconnect diagnosis.

Latest Web v3 wheel/quality/auth refinement:

- User reported that device selection still asked for a password, scroll direction was inverted, scroll was too coarse/fast, Direct YUV felt identical, Video mode forced Monitor on, and Fast/Balanced/Best did not feel meaningfully different.
- Investigated the bundled legacy RustDesk WebClient behavior:
  - wheel events use `type: "wheel"` with protocol `x/y` as wheel units, not canvas coordinates
  - legacy Flutter WebClient converts wheel deltas to inverted `-1/0/1` steps
  - legacy WebClient can auto-login from saved address-book `hash` by decoding it into stored peer `password` bytes
- Changed Web v3 build marker to `20260517-wheel-quality1`.
- Wheel fix:
  - wheel direction is inverted to match RustDesk protocol expectations
  - wheel units are now small `-1/0/1` steps like the old WebClient
  - small trackpad deltas are accumulated before sending, so touchpad scrolling remains precise without zero-spam
  - wheel events with no accumulated step are swallowed locally and not sent as no-op remote events
- Saved credential fix:
  - Web v3 now checks both address-book `password` and `hash`
  - if `hash` exists, it is decoded and stored into the protocol peer cache as remembered password bytes, so the RustDesk transport can auto-login without showing a typed password
  - if only a plain password exists, the connection password field is still auto-filled
- Quality/control fix:
  - `Reaction` label was renamed to `Fast`
  - `Video mode` label was renamed to `Video boost`
  - Video boost no longer forces Monitor on
  - Video boost now applies `Best` + `60 FPS` and sends live image-quality when connected
  - quality selection now applies meaningful profiles:
    - Fast caps local frame pacing at 20 FPS and sends RustDesk `Low`
    - Balanced uses 30 FPS and sends RustDesk `Balanced`
    - Best uses 60 FPS and sends RustDesk `Best`
  - Direct YUV remains a renderer-path toggle only; it may look identical when the browser/driver path is already using the same decoded VP9 frames or YUV direct rendering is unavailable.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-wheel-quality1`.
  - `/web3/app.js?v=20260517-wheel-quality1` returns 200 and contains `WEB3_BUILD`, `decodeAddressBookHash`, inverted wheel sign, no forced `showMonitor = true`, and `applyQualityProfile`.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest Web v3 wheel smoothness refinement:

- User reported the new scroll path felt very laggy/delayed and browser content still showed color corruption.
- Root cause in the previous wheel fix:
  - wheel residuals were consumed only one step per browser wheel event
  - large mouse-wheel deltas could leave residual "debt" that made later scroll feel delayed or sticky
- Changed Web v3 build marker to `20260517-wheel-smooth1`.
- Replaced immediate per-event wheel sending with frame-level coalescing:
  - wheel deltas are accumulated during the current animation frame
  - each frame flushes at most a small capped number of RustDesk wheel steps
  - direction changes clear stale residuals so old scroll debt does not fight the new direction
  - idle gaps reset the accumulator
  - no-op wheel packets are no longer sent
- Added a clearer Direct YUV diagnostic:
  - if Direct YUV is enabled but the browser/GPU path is unavailable, Video help now says rendering remains on RGBA.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-wheel-smooth1`.
  - `/web3/app.js?v=20260517-wheel-smooth1` returns 200 and contains `WEB3_BUILD`, `queueWheelEvent`, `flushWheelEvents`, and the Direct YUV unavailable hint.
  - Served app.js no longer contains the old `normalizeWheelDelta` path.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.
- Remaining color corruption note:
  - If only browser content has green/red/purple blocks while normal desktop/apps look OK, the likely cause is remote Windows/browser GPU composition or multi-plane overlay capture.
  - Web v3 local renderer switches cannot fully fix that source-capture issue; run the Web v3 `Copy color fix` command on the remote Windows PC and restart the remote browser. If still corrupted, run `Copy MPO fix` as Administrator and sign out/in or reboot.

Latest Web v3 browser-color workaround:

- User reported that browser content still shows color corruption, while the native RustDesk client does not show the same issue.
- Current assessment:
  - Native RustDesk working means the remote desktop/server path is not generally broken.
  - The corruption is isolated to the Web v3 / legacy WebClient browser-render path or to how browser windows are captured/encoded for that path.
  - Native RustDesk uses a different client decoder/renderer and can avoid browser WebGL/readback/composition problems that the web bridge still hits.
- Changed Web v3 build marker to `20260517-safe-browser1`.
- Added `Copy safe browser` to Video help:
  - copies a PowerShell command that launches Chrome/Edge with a temporary profile
  - disables GPU, DirectComposition, GPU compositing, zero-copy, accelerated video decode/encode, Vulkan, Skia renderer, Canvas OOP rasterization, DComp presenter, and DComp visual tree
  - opens NodeSeek by default so the user can test the exact page in a no-GPU browser window on the remote PC
- Strengthened the color-fix guidance to recommend Safe browser when reopening the normal browser still shows corruption.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-safe-browser1`.
  - `/web3/app.js?v=20260517-safe-browser1` returns 200 and contains `WEB3_BUILD`, `buildSafeBrowserCommand`, and DirectComposition/overlay-disabling flags.
  - Web v3 HTML contains `copySafeBrowserBtn`.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest Web v3 simple menu pass:

- User asked to stop exposing too many technical controls and make the Web v3 client simple and easy by default.
- Changed Web v3 build marker to `20260517-simple-menu1`.
- Simplified the default Web v3 menu:
  - default controls now focus on Connect, Disconnect, Reconnect, Fullscreen, Mode, and Fix browser video
  - Mode now exposes only `Fast`, `Balanced`, and `Quality`
  - `Fix browser video` is the single visible action for the common browser-video/color problem
- Moved expert controls behind an `Advanced` expander:
  - Scale
  - FPS
  - Display
  - Cursor
  - Mute
  - Clipboard off
  - Video boost
  - Monitor
  - Direct YUV
  - Diagnostics
- Diagnostics still contains the lower-level tools:
  - Safe browser command
  - MPO fix command
- Updated user-facing text from "color fix" to the simpler "Fix browser video" wording where appropriate.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-simple-menu1`.
  - `/web3/app.js?v=20260517-simple-menu1` returns 200 and contains `WEB3_BUILD`.
  - Web v3 HTML contains the visible `Fix browser video` button, `advanced-panel`, hidden `copySafeBrowserBtn`, and `Quality` mode label.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest Web v3 Original scale fix:

- User reported that Fullscreen with Advanced -> Scale -> Original looked wrong.
- Root cause:
  - Original scale used intrinsic canvas sizing with top anchoring (`top: 0`) and no viewport guard.
  - In fullscreen or large browser windows this could look cropped, pushed upward, or inconsistent with the centered Adaptive mode.
- Changed Web v3 build marker to `20260517-simple-scale1`.
- Updated Original scale behavior:
  - if the remote desktop is smaller than the viewport, Original keeps native 1:1 size and centers it
  - if the remote desktop is larger than the viewport, Original scales down to fit inside the viewport while preserving aspect ratio
  - removed the top-start anchoring so Original is centered like Adaptive
- Added `--canvas-original-width` and `--canvas-original-height` CSS variables computed from the remote frame size and viewport size.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-simple-scale1`.
  - `/web3/app.js?v=20260517-simple-scale1` returns 200 and contains `WEB3_BUILD` and `canvas-original-width`.
  - `/web3/styles.css?v=20260517-simple-scale1` returns 200 and contains the new Original scale CSS.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.

Latest Web v3 web-only color corruption mitigation:

- User emphasized that the native RustDesk client does not show the color corruption; only Web v3/web client does.
- Updated assessment:
  - This points away from the RustDesk server and general remote desktop capture path.
  - The strongest suspect is now the reused legacy WebClient render pipeline, especially the hidden WebGL `YUVCanvas` -> `readPixels` -> RGBA path.
  - Native RustDesk uses a different decoder/renderer, so it can be correct while the browser bridge corrupts colors.
- Changed Web v3 build marker to `20260517-cpu-yuv1`.
- Added `forceLegacyCpuYuvRenderer()` before loading the legacy WebClient module:
  - after loading `yuv-canvas-1.2.6.js`, Web v3 monkey-patches `YUVCanvas.WebGLFrameSink.isAvailable()` to return false for the legacy bundle
  - this forces the old bundle to use its CPU `yuv.js` conversion worker instead of WebGL readback
  - Direct YUV initialization still happens before this patch, but default Direct YUV remains off
- Diagnostics now show `CPU RGBA` when this safer renderer path is active.
- Rebuilt and restarted `rustdesk-api`.
- Verification:
  - `/web3/` returns 200 and references `20260517-cpu-yuv1`.
  - `/web3/app.js?v=20260517-cpu-yuv1` returns 200 and contains `WEB3_BUILD`, `forceLegacyCpuYuvRenderer`, `WebGL readback disabled`, and `CPU RGBA`.
  - Public `21114/_admin/` remains 404; private `21124/_admin/` remains 200; `/api/web-v3/config` remains 200.
- Next diagnostic:
  - If `20260517-cpu-yuv1` still shows the same red/green blocks, the issue is likely in the OGV VP9 decode/frame layout itself or the RustDesk web protocol bundle, not in the WebGL readback stage.

Latest skill addition:

- Added Codex skill `confidence-loop` at `C:\Users\tanq\.codex\skills\confidence-loop`.
- The official `quick_validate.py` could not run because local Python is missing `PyYAML`.
- A basic local frontmatter/content validation passed.

### WebClient v1

Status: partially fixed.

Fixes done:

- `/webclient-config/index.js` now returns same-origin `api-server`.
- It also sets custom rendezvous server and key from API config.

User must hard refresh or clear WebClient localStorage when old config is cached:

```js
localStorage.clear()
```

Known v1 gaps:

- WebClient v1 may still fail for some flows.
- v1 UI is old and not the desired long-term target.
- WebClient buttons currently point to `/webclient`, not a finished v3.

### WebClient v2 Investigation

Status: investigated, not integrated.

Findings:

- `rustdesk-api-v2` contains backend references to `/webclient2`.
- It has `ServerConfigV2` and docs mentioning v2 Preview.
- It does not contain `resources/web2`.
- Therefore the local `rustdesk-api-v2` folder does not include the old v2 frontend static files.

Important decision:

- Do not directly copy DMCA-removed official v2 code.
- Build a self-owned Web v3 implementation using legal/self-written code and the available backend ideas.

### QT Desk Custom Client Plan

Status: planned.

Added:

- `docs/qt-desk-custom-client-plan.md`
- `docs/github-publication-roadmap.md`

Decision:

- It is technically possible to make custom QT Desk clients, but public/open-source release must respect upstream license and trademark boundaries.
- Do not copy RustDesk Pro custom-client generator implementation.
- Do not use RustDesk branding for QT Desk binaries.
- Keep upstream notices and AGPL/MIT obligations.
- Start with a safe open-source builder that creates config/deployment packages, then move into a source fork rebrand/build farm.

Target features:

- App name/icon/logo replacement.
- Preconfigured ID/relay/API server and public key.
- Bidirectional, incoming-only, and outgoing-only build profiles.
- Lockdown toggles for install, settings, address book, TCP listen, account login, file transfer, clipboard, and other advanced options.
- Preset/default/override settings.
- Windows first, then macOS/Linux, Android later.

### QT Desk Clean-Room Direction

Status: planned and documented.

Added:

- `docs/qt-desk-clean-room-roadmap.md`

Decision:

- Long-term goal is a QT Desk-native stack, not only a RustDesk-branded fork.
- Existing RustDesk-derived code remains useful as a compatibility bridge and migration path, but must stay clearly attributed.
- New QT Desk code should be written in clean-room modules with original specs, original UI, and original protocol documents.
- OpenViking can be used as an optional project-memory/context database for architecture decisions, clean-room evidence, issue history, and release runbooks. It is not a remote desktop protocol, capture pipeline, relay, or video engine.

First native milestones:

- Add legal/notice/trademark files and a derived-code map.
- Add OpenViking optional-service design.
- Draft `QTDP v0`, a QT Desk-native WebSocket protocol.
- Add a native WebSocket demo stream endpoint for `/web3/`.
- Make Web v3 switchable between the current RustDesk compatibility bridge and a QT Desk-native test stream.

### Web v3 Phase 1 Backend Skeleton

Status: implemented and Docker build-verified.

Changed areas:

- `docs/web-v3-protocol.md`
- `rustdesk-api/model/webV3.go`
- `rustdesk-api/service/webV3.go`
- `rustdesk-api/http/request/api/webV3.go`
- `rustdesk-api/http/request/admin/webV3.go`
- `rustdesk-api/http/response/api/webV3.go`
- `rustdesk-api/http/response/admin/webV3.go`
- `rustdesk-api/http/controller/api/webV3.go`
- `rustdesk-api/http/controller/admin/webV3.go`
- `rustdesk-api/http/router/api.go`
- `rustdesk-api/http/router/admin.go`
- `rustdesk-api/cmd/apimain.go`
- `rustdesk-api/service/service.go`

Main additions:

- Added the first Web v3 protocol document.
- Added public `/api/web-v3` route skeleton:
  - `GET /config`
  - `POST /session`
  - `GET /session/:session_id`
  - `POST /session/:session_id/refresh`
  - `POST /session/:session_id/revoke`
  - `POST /ws-token`
  - `POST /shared-peer`
- Added admin `/api/admin/web-v3` route skeleton:
  - share create/list/revoke
  - session list/revoke
  - audit list
  - settings get/post placeholder
- Added database models for Web v3 sessions, WebSocket token digests, shares, and audit events.
- Bumped API database version to migrate the Web v3 tables.
- Web v3 share/session flows issue short-lived raw tokens only at creation time and store token digests.
- Legacy `/webclient` routes and static files were left untouched.

Verification note:

- Local `go`/`gofmt` is not available in PATH, so `gofmt` was run through `golang:1.23-alpine`.
- `docker compose build rustdesk-api` passed after formatting and produced `tanqt0728/rustdesk-api-fixed:local`.

### Web v3 Phase 2 Admin Share Flow

Status: partially implemented and smoke-tested locally.

Changed areas:

- `rustdesk-api/resources/admin/index.html`
- `rustdesk-api/resources/admin/styles.css`
- `rustdesk-api/resources/admin/app.js`

Main additions:

- Admin device and address-book rows now show Web v3-oriented actions:
  - Open App
  - Web v3
  - Share Web
  - Copy Link
  - Save AB where applicable
- Added a Web v3 share modal with:
  - peer identity display
  - expiration selector
  - once-only token toggle
  - permission toggles
  - generated share URL output
  - copy/open buttons
- Added admin log shortcuts for:
  - Web v3 sessions
  - Web v3 shares
  - Web v3 audit
- Share creation uses `POST /api/admin/web-v3/share`.
- Copy Link creates a default one-hour, once-only Web v3 share and copies it.
- Share/session revoke actions use the Phase 1 revoke endpoints.
- Sidebar now points to `/web3/` instead of old `/webclient/`.

Verification:

- `docker compose --env-file .env -f docker-compose.yml -f docker-compose.windows.yml up -d --build` passed locally.
- API container started and migrated database version 266.
- `GET http://127.0.0.1:21114/api/web-v3/config` returned success.
- `GET http://127.0.0.1:21114/_admin/` returned HTTP 200.
- `/_admin/app.js` contains the new `Share Web` action.
- `rustdesk-server` health is `healthy`.

Known Phase 2 gaps:

- Browser click-through still needs testing with the current admin password.
- `/web3/` frontend shell is still Phase 3, so Web v3 open/share links are prepared but not yet a real remote-control UI.
- Web v3 settings are currently returned by placeholder endpoints and not persisted.

### Web v3 Phase 3 Frontend Shell

Status: minimal shell implemented and smoke-tested locally.

Changed areas:

- `rustdesk-api/http/router/router.go`
- `rustdesk-api/resources/web3/index.html`
- `rustdesk-api/resources/web3/styles.css`
- `rustdesk-api/resources/web3/app.js`

Main additions:

- `/web3/` is now served as a static app.
- Supported hash inputs:
  - `/web3/#/?id=123456789`
  - `/web3/#/?share_token=...`
  - `/web3/#/?session_id=...`
- The shell parses route parameters and bootstraps against Phase 1 APIs.
- Direct peer mode uses the admin token from `localStorage.rd_admin_token` as `Authorization: Bearer ...`.
- Share-token mode creates a Web v3 session without admin credentials.
- Existing session mode loads metadata by session ID.
- The page shows session status, peer metadata, permissions, expiry, reconnect, fullscreen, and a placeholder remote canvas.

Verification:

- Rebuilt and restarted the local Windows Docker Compose stack.
- `GET http://127.0.0.1:21114/web3/` returned HTTP 200.
- `GET http://127.0.0.1:21114/web3/app.js` returned the new bootstrap script.
- `GET http://127.0.0.1:21114/api/web-v3/config` still returned success.

Known Phase 3 gaps:

- The remote-control transport is not implemented yet.
- The canvas is a placeholder until Phase 4 connects to the RustDesk web protocol.
- Browser click-through for direct peer/session/share flows still needs manual testing with a logged-in admin session.

### Web v3 Phase 4 Remote Connection Bridge

Status: first bridge implemented, real connection reached relay/security handshake, performance tuning in progress.

Changed areas:

- `rustdesk-api/resources/web3/index.html`
- `rustdesk-api/resources/web3/styles.css`
- `rustdesk-api/resources/web3/app.js`
- `rustdesk-api/resources/web3/libopus.js`
- `rustdesk-api/resources/web3/yuv.js`

Main additions:

- Web v3 shell now has Connect, Disconnect, Reconnect, and Fullscreen controls.
- `app.js` dynamically loads the existing RustDesk web protocol bundle from `/webclient/js/dist/index.js`.
- It also loads existing decoder helpers from `/webclient/ogvjs-1.8.6/ogv.js` and `/webclient/yuv-canvas-1.2.6.js`.
- Added Web v3 worker wrappers for:
  - `/web3/libopus.js`
  - `/web3/yuv.js`
- Direct peer sessions seed the protocol layer with:
  - `custom-rendezvous-server`
  - `key`
  - `remote-id`
  - `access_token` from `localStorage.rd_admin_token` when available
- Protocol events are bridged into the Web v3 UI:
  - status messages
  - password prompt
  - peer info and display sizing
  - decoded RGBA frame rendering to the Web v3 canvas
- Basic mouse, wheel, keydown, and keyup forwarding is wired to the protocol layer after connection.
- Web v3 now rewrites the rendezvous host to the current browser host when opened from `127.0.0.1`, `localhost`, or `::1`.
- Local `.env` was updated from stale `192.168.15.115` values to current Wi-Fi IP `192.168.88.10`:
  - `RUSTDESK_ID_PUBLIC=192.168.88.10:21116`
  - `RUSTDESK_RELAY_PUBLIC=192.168.88.10:21117`
  - `RUSTDESK_API_PUBLIC_URL=http://192.168.88.10:21114`
- Browser test reached:
  - rendezvous WebSocket open on `192.168.88.10:21118`
  - relay WebSocket open on `192.168.88.10:21119`
  - password prompt accepted
  - secure handshake completed
  - remote frames displayed
- The old protocol bundle still emits public probe errors for `rs-sg`, `rs-cn`, and `rs-us`; these are currently noise when the private relay connection succeeds.
- Added initial performance tuning in `/web3/app.js`:
  - seed v1 peer options from Web v3 client settings
  - disable audio by default
  - keep remote cursor enabled
  - override the duplicate `_draw` callback so the old bridge does not do the expensive global frame conversion twice
  - throttle RGBA canvas painting through `requestAnimationFrame` at about 20 FPS and drop backlog frames
  - hide the overlay as soon as the first remote frame renders
- Compared the local `rustdesk-api-v2` reference:
  - `/api/server-config-v2` only returns `id_server` and `key`
  - `/api/server-config` returns `id_server`, `key`, and address-book peers
  - `/api/shared-peer` returns `id_server`, `key`, and one shared peer
  - v2 API did not expose the full client display/quality option set as server settings
  - old client options are mainly browser/local peer options such as `view-style`, `image-quality`, `show-remote-cursor`, `disable-audio`, `disable-clipboard`, `lock-after-session-end`, and `privacy-mode`
- Added Web v3 client controls:
  - quality: reaction/low, balanced, best
  - scale: adaptive, original, stretch
  - FPS cap: 15/20/30/60
  - display selector populated from peer info
  - remote cursor toggle
  - mute toggle
  - clipboard-off toggle
  - settings persist in `localStorage.qt_desk_web3_settings`
- Added a browser-side blocker for the old bundle's public `rs-sg`, `rs-cn`, and `rs-us` WebSocket probe attempts before loading the protocol module.
- Improved RGBA frame sizing by matching incoming byte length against peer displays and common desktop resolutions before falling back to width inference.
- Browser retest confirmed:
  - public probe errors are gone
  - rendezvous and relay connect successfully
  - secure handshake completes
  - remote image is visible
  - remaining issue was lack of mouse/keyboard control
- Added Web v3 input-layer fixes:
  - canvas is focusable with `tabindex=0`
  - mouse movement now sends protocol `send_mouse` with type `move`
  - drag movement carries the active mouse button bit
  - move events are throttled through `requestAnimationFrame`
  - keyboard events are only sent after the remote canvas has focus or the stage is fullscreen
  - form controls no longer leak keyboard events to the remote peer
  - canvas uses `touch-action: none` as groundwork for mobile pointer/touch handling
- Browser retest confirmed input control is now working well enough for the next UX pass.
- Added floating HUD layout:
  - top toolbar no longer occupies page layout height
  - bottom session bar no longer occupies page layout height
  - remote stage is fixed full-viewport
  - canvas sizing now uses the full browser viewport instead of subtracting toolbar/footer height
  - compact top-right `Tools` bubble shows status and peer
  - clicking `Tools` opens connection/settings controls
  - `Info` toggles the bottom peer/permissions/expiry drawer
  - connected state auto-collapses the control panel
- User retest showed the top-right bubble still blocked remote UI and could show stale `error` even when the relay connection was fine.
- Revised HUD into a hidden edge menu:
  - collapsed state is now a slim right-edge `Menu` tab near vertical center
  - collapsed state hides peer and status, so stale status cannot visually block or distract
  - menu tab is half tucked offscreen and slides in on hover/focus/open
  - expanded state still opens the full settings panel
- Added non-fatal protocol-noise filtering:
  - after a real connection is active, `Timeout` and rendezvous/relay probe-style errors no longer overwrite the connected status
  - unhandled promise rejection suppression now also applies while protocol loading is in progress
- User retest showed the edge menu was too hard to see/use, still felt awkward, and the expanded panel was hard to read and could not be moved.
- Replaced edge menu with a top-center remote-desktop style menu:
  - collapsed state is a small visible `Menu` pill at the top center
  - no left/right screen space is reserved
  - corners are free for remote UI
  - expanded controls are a narrower two-column palette
  - palette header is draggable
  - palette position is saved in `localStorage.qt_desk_web3_hud`
  - `Pin` keeps the palette open
  - `Close` hides it immediately
  - outside click hides the palette only when it is not pinned
- User retest rejected the draggable menu: dragging could make it disappear, and the page still had side margins.
- Replaced draggable menu with fixed bottom command bar:
  - no dragging
  - no pinning
  - no saved HUD position
  - collapsed state is fixed at bottom center
  - expanded controls are fixed above the bottom menu
  - outside click closes the controls
  - stage and canvas now use `100vw x 100vh` with no aspect-ratio letterboxing, so no left/right space is reserved
- Added quality/FPS monitor:
  - `Monitor` toggle in the bottom command menu
  - small top-left monitor overlay when enabled
  - shows rendered FPS
  - shows average browser canvas render time
  - shows dropped frame count from Web v3 throttle
  - captures old protocol console metrics for `video decoder: N` and `gl: N`
  - shows current quality mode
  - monitor setting persists in `localStorage.qt_desk_web3_settings`
  - changing image quality requests a protocol video refresh shortly after applying
- Added direct YUV rendering path for Web v3:
  - Web v3 now creates a separate visible `remoteVideoCanvas` below the input canvas
  - the old protocol `Connection.draw()` can now skip its fallback RGBA bridge when a draw callback returns `true`
  - Web v3 draws decoded YUV frames directly with `YUVCanvas.drawFrame`
  - the transparent `remoteCanvas` remains the focus/input layer for mouse and keyboard coordinates
  - the previous RGBA `readPixels -> onRgba -> putImageData` path remains as fallback when direct YUV is unavailable
  - the monitor shows `YUV` in the GL field while the direct renderer is active
- Reintroduced desktop-only draggable Web v3 menu:
  - expanded menu can be dragged by its header on non-touch desktop-sized browsers
  - menu position is clamped inside the viewport
  - menu position persists in `localStorage.qt_desk_web3_hud`
  - double-clicking the menu header resets the saved position
  - mobile/narrow layouts ignore saved drag position and remain bottom-fixed
- Hardened Web v3 control UX:
  - draggable menu now uses delegated header drag handling from the panel
  - document-level pointer/mouse move and release handlers keep dragging stable outside the panel bounds
  - pointer capture failures are tolerated instead of aborting drag state
  - monitor/cursor/mute/clipboard toggles now use a single stable setting update path
- Fixed the Web v3 control-panel bug found during retest:
  - `hudPanel` was missing from the cached DOM reference map, so menu positioning/drag code threw after the menu opened
  - desktop menu dragging no longer rejects Windows desktop browsers just because `navigator.maxTouchPoints` is non-zero
  - Monitor now has direct `onchange/oninput` fallback wiring plus early global bridge functions
  - Monitor now shows `Received` and `Mode` so it has useful state even before live video frames arrive
  - Fullscreen now targets the whole `.web3-shell`, keeping the HUD/menu in the fullscreen layer instead of fullscreening only the stage/canvas
- Fixed the "MENU click opens nothing" regression:
  - the inline menu fallback and the normal `addEventListener` handler were both toggling HUD state, so one click opened and immediately closed the panel
  - removed the duplicate JS click listener and kept `window.qtDeskToggleHud` as the single menu toggle path
  - removed the transformed parent positioning issue by changing `.toolbar` from `left: 50% + translateX(-50%)` to a full-width fixed toolbar with centered children
  - this keeps the fixed HUD panel positioned against the viewport instead of a transformed containing block
- Added Web v3 disconnect resilience:
  - server logs showed API auth and relay pairing succeeded, so quick disconnects are more likely post-handshake transport closes than auth rejection
  - Web v3 now distinguishes manual disconnects from unexpected transport resets
  - unexpected reset/close after relay/connected state schedules automatic reconnect up to 3 attempts
  - reconnect status now shows `Reconnecting (N/3)` with the last close reason
- Replaced the ugly first-load canvas shell with a Web v3 pre-connect screen:
  - `/web3/#/?id=...` now opens to a centered connection card instead of the debug grid canvas
  - the card shows the route peer/session identity before the backend session finishes loading
  - password entry now happens in the page, not through `window.prompt`
  - password requests from the RustDesk protocol can reopen the same card, including a wrong-password retry state
  - the remote canvas stays hidden until the user connects or a real remote frame arrives
  - mobile bottom menu centering was corrected while touching the Web v3 shell styles
- Added stronger Web v3 disconnect/stall UX and draggable menu button:
  - the collapsed `MENU` pill itself can now be dragged on desktop-sized browsers
  - the menu button position is clamped inside the viewport and persists in `localStorage.qt_desk_web3_menu`
  - double-clicking the `MENU` pill resets it to the default bottom-center position
  - dragging the `MENU` pill no longer accidentally toggles the settings panel
  - Web v3 now watches private RustDesk rendezvous/relay WebSockets on ports `21118` and `21119`
  - WebSocket `error`/`close` and old protocol `WebSocket is already in CLOSING or CLOSED state` console failures now surface in the UI
  - unexpected disconnects show a centered interruption panel with `Reconnect` and `Connection screen`
  - reconnect now actually reconnects the remote transport after refreshing the Web v3 session when possible
  - connected sessions now detect frame stalls after about 6 seconds without new frames and show a clear frozen-image warning
- Added browser-video capture compatibility support:
  - Web v3 menu now includes `Video mode`
  - `Video mode` applies a one-time Best quality, 60 FPS, and Monitor-on preset, then refreshes the video stream when connected
  - added `tools/windows-browser-capture-compat.ps1` for the remote Windows machine to disable Chrome/Edge hardware acceleration policies
  - the script also supports optional Administrator-only `-DisableMpo` to disable Windows DWM multi-plane overlay for stubborn black/frozen browser video captures
  - added `docs/browser-video-capture-compat.md` with the compatibility procedure, undo command, and DRM/HDCP capture boundary
- Fixed the Web v3 Monitor toggle interaction:
  - `Video mode` no longer continuously forces `showMonitor=true`
  - users can now untick Monitor after enabling Video mode

Verification:

- Rebuilt and restarted local Docker Compose stack for `rustdesk-api`.
- `GET http://127.0.0.1:21114/web3/` returned HTTP 200.
- `GET http://127.0.0.1:21114/web3/app.js` contains `loadProtocolRuntime`.
- `GET http://127.0.0.1:21114/web3/libopus.js` returned HTTP 200.
- `GET http://127.0.0.1:21114/web3/yuv.js` returned HTTP 200.
- `Test-NetConnection 192.168.15.115 -Port 21118` failed, confirming the old `.env` address was stale.
- `Test-NetConnection 192.168.88.10 -Port 21114/21118/21119` passed.
- After restart, `GET http://127.0.0.1:21114/api/web-v3/config` returns `192.168.88.10`.
- `rustdesk-server` health is `healthy`.
- Rebuilt/restarted `rustdesk-api` after frame-throttle changes.
- `GET http://127.0.0.1:21114/web3/app.js` contains `targetFrameMs`.
- `GET http://127.0.0.1:21114/api/web-v3/config` returns current `192.168.88.10` config.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after adding client settings controls and probe blocker.
- `GET http://127.0.0.1:21114/web3/` contains `qualitySelect`.
- `GET http://127.0.0.1:21114/web3/app.js` contains `installPublicProbeBlocker`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `canvas-ratio`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after adding input-layer fixes.
- `GET http://127.0.0.1:21114/web3/app.js` contains `queueMouseMove`.
- `GET http://127.0.0.1:21114/web3/` contains `tabindex="0"`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `touch-action`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after adding floating HUD.
- `GET http://127.0.0.1:21114/web3/` contains `hudToggle`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `hud-summary`.
- `GET http://127.0.0.1:21114/web3/app.js` contains `setHudOpen`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after hidden menu and non-fatal error filtering changes.
- `GET http://127.0.0.1:21114/web3/` contains `Menu`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `translateX(17px)`.
- `GET http://127.0.0.1:21114/web3/app.js` contains `isNonFatalProtocolNoise`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after replacing the edge menu with draggable top-center menu.
- `GET http://127.0.0.1:21114/web3/` contains `pinToggle`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains the two-column control grid.
- `GET http://127.0.0.1:21114/web3/app.js` contains `startHudDrag`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after replacing draggable menu with fixed bottom command bar.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `width: 100vw`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `bottom: 14px`.
- `GET http://127.0.0.1:21114/web3/app.js` no longer contains `startHudDrag`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after adding quality/FPS monitor.
- `GET http://127.0.0.1:21114/web3/` contains `qualityMonitor`.
- `GET http://127.0.0.1:21114/web3/styles.css` contains `quality-monitor`.
- `GET http://127.0.0.1:21114/web3/app.js` contains `renderQualityMonitor`.
- `rustdesk-server` health is still `healthy`.
- Rebuilt/restarted `rustdesk-api` after adding direct YUV rendering.
- `GET http://127.0.0.1:21114/web3/` returns HTTP 200 and contains `remoteVideoCanvas`.
- `GET http://127.0.0.1:21114/web3/app.js` returns HTTP 200 and contains `queueYuvFrame`.
- `GET http://127.0.0.1:21114/web3/styles.css` returns HTTP 200 and contains `direct-yuv`.
- `GET http://127.0.0.1:21114/_admin/` returns HTTP 200.
- `GET http://127.0.0.1:21114/api/web-v3/config` returns the current `192.168.88.10` rendezvous/relay config.
- `Test-NetConnection 192.168.88.10 -Port 21114/21118/21119` passed.
- `rustdesk-server` health is still `healthy`.
- Chrome headless screenshot of `/web3/#/?id=test` at 1366x768 confirmed the canvas fills the viewport with no side margins and only the bottom-center collapsed `MENU` pill visible.
- Chrome headless CDP interaction opened the menu and enabled Monitor; DOM metrics showed `stage` and input canvas exactly match the viewport, `scrollWidth/scrollHeight` match the viewport, and Monitor displays FPS/render/decoder/GL/dropped/quality fields.
- Rebuilt/restarted `rustdesk-api` after adding desktop draggable menu.
- `GET http://127.0.0.1:21114/web3/app.js` contains the draggable menu code and `qt_desk_web3_hud`.
- Headless Chrome confirmed the draggable menu enable condition is true on desktop-sized non-touch viewports; synthetic drag events did not move the panel in headless, so a real desktop browser retest is still recommended.
- Rebuilt/restarted `rustdesk-api` after the admin control-console redesign and Web v3 drag/toggle hardening.
- `GET http://127.0.0.1:21114/_admin/` returns HTTP 200 and contains `webView`, `dashboardSummary`, `Web Access`, and `readinessList`.
- `GET http://127.0.0.1:21114/_admin/app.js` contains `renderWebAccess`, `currentEndpoints`, and `data-view-jump`.
- `GET http://127.0.0.1:21114/_admin/styles.css` contains `hero-panel`, `quick-card`, `status-list`, and `action-card`.
- `GET http://127.0.0.1:21114/web3/app.js` contains delegated drag and document pointer handlers plus `queueYuvFrame` and `renderQualityMonitor`.
- `GET http://127.0.0.1:21114/api/web-v3/config` still returns the current `192.168.88.10` rendezvous/relay config.
- `rustdesk-server` health is still `healthy`.
- Chrome headless screenshot of `/_admin/` confirmed the unauthenticated admin shell renders with the new Web Access nav and no obvious layout break.
- Chrome headless screenshot of `/web3/#/?id=test` confirmed the stage still fills the viewport with no side margins and only the bottom-center `MENU` pill visible.
- Chrome/CDP confirmed the Monitor DOM fields exist and the desktop drag enable condition is true; CDP synthetic events still do not reliably exercise the same trusted browser event path as a physical mouse.
- Rebuilt/restarted `rustdesk-api` after fixing `hudPanel`, Monitor, drag, and fullscreen behavior.
- `GET http://127.0.0.1:21114/web3/` contains `qtDeskStartHudDrag`, `qtDeskSetSetting`, `monitorReceived`, and `monitorMode`.
- `GET http://127.0.0.1:21114/web3/app.js` contains `hudPanel: document.getElementById("hudPanel")`, `window.qtDeskSetSetting`, `window.qtDeskStartHudDrag`, `setMonitorVisible`, and `toggleFullscreen`.
- Chrome/CDP confirmed `window.qtDeskSetSetting` is now a function, Monitor becomes visible, and Monitor text shows `FPS`, `Received`, `Mode`, `Dropped`, and `Quality`.
- Chrome/CDP confirmed drag start no longer throws the previous `hudPanel` undefined error.
- `rustdesk-server` health is still `healthy`, and `/api/web-v3/config` still returns the current `192.168.88.10` rendezvous/relay config.
- Rebuilt/restarted `rustdesk-api` after the MENU click regression fix.
- Chrome/CDP confirmed clicking `MENU` changes HUD from `toolbar hud-collapsed` to `toolbar`, sets `aria-expanded=true`, and places the panel inside the viewport at roughly `720x356`.
- Served `/web3/app.js` contains `window.qtDeskToggleHud` and no longer contains the duplicate `els.hudToggle.addEventListener("click", toggleHud)` binding.
- Served `/web3/styles.css` confirms toolbar uses `left: 0`, `right: 0`, and `transform: none`.
- Rebuilt/restarted `rustdesk-api` after adding disconnect resilience.
- Served `/web3/app.js` contains `scheduleReconnect`, `shouldAutoReconnect`, `manualDisconnect`, `Reconnecting (`, and `setByName("reconnect"`.
- Server logs during the reported quick-disconnect window showed `API auth accepted` and relay `got paired`; one relay session later logged `closed`, pointing to post-connect transport closure rather than ID/key/token rejection.
- Rebuilt/restarted `rustdesk-api` after adding the Web v3 pre-connect screen.
- `GET http://127.0.0.1:21114/web3/` returned HTTP 200 and contains `connectPanel`, `connectPassword`, and `stage preconnect`.
- Served `/web3/app.js` contains `showConnectPanel`, `sendPasswordToProtocol`, and `renderRouteIdentity`, and no longer contains `window.prompt`.
- `GET http://127.0.0.1:21114/api/web-v3/config` still returns the current `192.168.88.10` rendezvous/relay config.
- `GET http://127.0.0.1:21114/_admin/` still returns HTTP 200.
- Chrome headless screenshot of `/web3/#/?id=test` confirmed the first screen now shows the connection/password card, with no debug grid canvas visible.
- Chrome/CDP confirmed the Web v3 MENU still opens, Monitor still shows FPS/render/received/decoder/GL/mode/dropped/quality fields, and desktop drag state still works after adding the pre-connect card.
- Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy after the rebuild.
- Rebuilt/restarted `rustdesk-api` after adding draggable `MENU` and disconnect/stall UI.
- Served `/web3/app.js` contains `watchRustDeskSocket`, `markTransportProblem`, `checkFrameStall`, `qt_desk_web3_menu`, and `reconnectRemote`; it still does not contain `window.prompt`.
- Served `/web3/` and `/_admin/` both return HTTP 200, and `/api/web-v3/config` still returns `192.168.88.10` rendezvous/relay config.
- Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy after the rebuild.
- `Test-NetConnection` passed for `127.0.0.1:21118`, `192.168.88.10:21118`, and `127.0.0.1:21119`.
- `rustdesk-server` logs show hbbs listening on websocket `:21118` and hbbr listening on websocket `:21119`.
- Chrome/CDP smoke test confirmed Web v3 JS loads, `MENU` opens, Monitor fields render, and the expanded menu drag path still enters dragging state.
- Rebuilt/restarted `rustdesk-api` after adding `Video mode` and browser capture compatibility docs/tools.
- Served `/web3/` returns HTTP 200 and contains `videoCompatToggle` and `Video mode`.
- Served `/web3/app.js` contains `videoCompatibility`, `maxFps = 60`, and `showMonitor = true`.
- PowerShell parser check for `tools/windows-browser-capture-compat.ps1` passed.
- Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy after the rebuild.
- Chrome/CDP smoke test confirmed the Web v3 menu still opens, Monitor still renders, and `Video mode` appears in the expanded menu.
- Rebuilt/restarted `rustdesk-api` after fixing the `Video mode`/Monitor toggle interaction.
- Served `/web3/app.js` no longer has `applyClientSettings()` forcing `showMonitor = true`; the only remaining `showMonitor = true` path is the one-time `Video mode` preset inside `updateClientSetting`.
- Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy after the Monitor toggle fix.
- Rebuilt/restarted `rustdesk-api` after Web v3 connection/admin hardening:
  - clean relay/rendezvous close events such as code `1005` during pre-connect/handshake no longer trigger a flashing reconnect panel
  - automatic reconnect attempts now stay in the compact status/overlay and only show the action panel after the retry limit or non-auto failure
  - password and connect commands now retry while the old protocol WebSocket is still `CONNECTING`, so wrong-timing errors no longer surface as raw browser exceptions
  - admin Web Access active session count now excludes expired/revoked/stale `preparing` sessions
  - Web v3 session listing marks old expired sessions as `expired` before returning admin data
  - dashboard connectable devices now merges admin devices, my devices, address book, and all address book entries instead of letting a 2-item address book hide other devices
  - device rows now show a clearer online/seen status line
  - admin Settings now allows admin users to edit ID server, relay server, API server, and public key at runtime, with config-file persistence attempted
- Verification after that hardening pass:
  - `docker compose ... build rustdesk-api` passed
  - `docker compose ... up -d rustdesk-api` restarted the API container
  - `/web3/`, `/_admin/`, and `/api/web-v3/config` returned HTTP 200/success
  - Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy
- Chrome/CDP smoke test confirmed `/web3/app.js` loads, MENU opens, Monitor renders, and desktop drag state still works
- Added Web v3 video/capture diagnostics:
  - menu now has `Video help`
  - diagnostics show received/rendered frames, current renderer, Video mode state, and last-frame age
  - diagnostics now show dark-frame streak and sampled brightness
  - diagnostics can copy the normal browser compatibility command and the Administrator MPO compatibility command
  - frame-stall detection now auto-opens the diagnostics panel and states the DRM/HDCP protected-video boundary clearly
  - continuous near-black rendered frames now trigger a distinct `Remote image is black` panel instead of being treated as a network disconnect
  - RGBA frames are sampled for brightness directly; YUV direct frames sample the luma plane when available
  - this does not bypass DRM/HDCP, but helps distinguish transport/rendering issues from capture blocking or hardware overlay behavior
  - verification confirmed `/web3/` contains `captureHelpBtn`, `capturePanel`, and `Copy MPO fix`
  - served `/web3/app.js` contains `toggleCaptureHelp`, `copyCaptureCommand`, `DRM/HDCP protected video`, and `windows-browser-capture-compat.ps1`
  - served `/web3/styles.css` contains `capture-panel` and `capture-grid`
  - rebuilt and restarted `rustdesk-api`; `/web3/`, `/api/web-v3/config`, and private `/_admin/` returned 200 while public `21114/_admin/` stayed 404
- Added Custom Clients MVP to the admin UI:
  - new admin sidebar entry `Custom Clients`
  - profile form with platform, app label, connection type, server preset, public key, note, and lockdown toggles
  - advanced default/override key-value settings
  - generated profile JSON
  - generated RustDesk `--config`-style config string
  - generated Windows PowerShell deployment script
  - downloadable deployment package zip containing `README.txt`, `profile.json`, `rustdesk-config.txt`, `install-windows.ps1`, `settings-default.txt`, and `settings-override.txt`
  - browser-local draft persistence in `localStorage.rd_admin_custom_client_draft`
  - no RustDesk Pro code or proprietary generator implementation copied
- Verification after Custom Clients MVP:
  - `docker compose ... build rustdesk-api` passed
  - `docker compose ... up -d rustdesk-api` restarted the API container
  - `/_admin/` returned HTTP 200 and contains `Custom Clients`, `ccName`, and `ccWindowsScript`
  - served `/_admin/app.js` contains `buildCustomClientProfile`, `buildWindowsDeploymentScript`, and `rd_admin_custom_client_draft`
  - rebuilt/restarted after package download support; private `/_admin/` contains `customClientDownloadPackageBtn` and `Download package`
  - served `/_admin/app.js` contains `downloadCustomClientPackage`, `createZip`, `CRC32_TABLE`, and `settings-override.txt`
  - Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy
- Added optional admin/API split mode:
  - new `docker-compose.admin-split.yml` override
  - new `RUSTDESK_API_GIN_ADMIN_ADDR` / `gin.admin-addr` support
  - `.env.example` now exposes `RUSTDESK_API_ADMIN_ADDR` and `RUSTDESK_API_ADMIN_HOST_PORT`, so the private admin port can be changed without editing compose files
  - when admin split is enabled, public `21114` serves public API/Web v3 but does not register `/_admin` or `/api/admin`
  - private admin listener serves `/_admin`, `/api/admin`, and the regular API needed by the admin UI
  - local split example maps admin to `127.0.0.1:21124`
- Verification for admin split mode:
  - `docker compose --env-file .env -f docker-compose.yml -f docker-compose.windows.yml -f docker-compose.admin-split.yml up -d --build rustdesk-api` passed
  - `http://127.0.0.1:21114/_admin/` returns 404
  - `http://127.0.0.1:21114/api/admin/login-options` returns 404
  - `http://127.0.0.1:21114/api/web-v3/config` returns 200
  - `http://127.0.0.1:21124/_admin/` returns 200
  - `http://127.0.0.1:21124/api/admin/login-options` returns 200
- Added GitHub/publication hardening files:
  - `NOTICE.md`
  - `TRADEMARKS.md`
  - `SECURITY.md`
  - `LICENSES/README.md`
  - `docs/derived-code-map.md`
  - updated `.gitignore` to exclude env files, DBs, backups, keys, logs, browser profiles, and build artifacts
  - updated `README.md` to use `rustdesk-selfhost-qt`, document admin split mode, explain public GitHub checklist, and clarify multi-license status
- Added public readiness tooling:
  - `tools/check-public-ready.ps1`
  - checks required publication files
  - checks publish-blocking artifacts outside ignored/reference paths
  - scans for high-confidence secret-like patterns without printing secret contents
  - treats `rustdesk-api-v2/` as local ignored reference by default
- Cleaned generated/private local artifacts:
  - removed Chrome/CDP test profiles and screenshot artifact
  - removed local `rustdesk-server/.env`
  - removed local `rustdesk-server/db_v2.sqlite3`
- Updated public image naming:
  - `.env.example` now uses `tanqt0728/rustdesk-selfhost-qt-server:latest`
  - `.env.example` now uses `tanqt0728/rustdesk-selfhost-qt-api:latest`
  - `docker-compose.yml` defaults now use the same public image names
  - `.github/workflows/docker-images.yml` uses the same image names
- Added Docker image publishing workflow hardening:
  - workflow now builds on pull requests without pushing
  - GHCR publishing is enabled by default through `GITHUB_TOKEN`
  - Docker Hub publishing is enabled only when `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets exist
  - image tags are generated through `docker/metadata-action` for branches, tags, SHA tags, and default-branch `latest`
- Added `docs/docker-publishing.md` with GHCR, optional Docker Hub, compose image override, and pre-publish check instructions.
- Verification:
  - `powershell -ExecutionPolicy Bypass -File tools\check-public-ready.ps1` passes
  - `docker compose --env-file .env -f docker-compose.yml -f docker-compose.windows.yml -f docker-compose.admin-split.yml config --quiet` passes
  - `git status --short --ignored` shows `.env` and `rustdesk-api-v2/` ignored
- Re-verified after docs/env hardening:
  - default compose mode: `21114/_admin`, `21114/api/admin/login-options`, and `21114/api/web-v3/config` all return 200
  - admin split compose mode: `21114/_admin` and `21114/api/admin/login-options` return 404, while `21114/api/web-v3/config`, `21124/_admin`, and `21124/api/admin/login-options` return 200
  - Docker Compose shows `rustdesk-api` up and `rustdesk-server` healthy

Known Phase 4 gaps:

- Full remote-control browser retest is still needed after direct YUV rendering to confirm the live remote image no longer tears and mouse/keyboard input still maps correctly.
- Real desktop browser retest is still recommended for the draggable menu, although Chrome/CDP confirms the drag code enters the expected state and saves position.
- Share-token mode currently creates a Web v3 session, but the existing RustDesk server does not yet validate the new scoped `ws_token`; direct logged-in peer mode is the first target.
- Keyboard mapping uses browser `event.key` and may need refinement against RustDesk's expected key names.
- Clipboard buttons, virtual display/resolution controls, and richer multi-monitor controls are still pending.
- Quality/FPS monitor is implemented and layout-tested; live remote retest is still needed to confirm decoder timing appears during active video and quality changes are visible/measurable.
- The v1 protocol bundle's public rendezvous latency probes are suppressed in Web v3, but should be removed cleanly in a later owned bundle.
- Custom Clients MVP currently generates configuration/deployment output only; real branded binary/installer building is still pending.

GitHub/open-source gaps:

- `rustdesk-api-v2/` is ignored for first public push; decide later whether it should be archived separately or removed from the workspace.
- Need test GitHub Actions in the real GitHub repo after push; Docker Hub requires optional `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` secrets.
- Need full README screenshots after final admin UI polish.

## Security Notes

- `.env` contains local secrets. Rotate before public deployment.
- Server private key must be protected and only included in admin backup export for trusted admins.
- Share links must use short-lived tokens by default.
- Admin commands must stay admin-only.
- Web sessions should never expose long-lived admin tokens to the browser.

## Open Work

High priority:

- Build Web v3 backend and frontend.
- Move admin WebClient buttons from v1 to Web v3 when v3 is usable.
- Add proper share modal with expiration, once/fixed token, password, and permissions.
- Finish professional admin pages.
- Verify backup export/import with the current admin password.
- Update README and Docker docs.

Medium priority:

- Add Web session logs and share revocation UI.
- Add Google/GitHub/OIDC/WebAuth setup guide.
- Add Docker Hub GitHub Actions build and push.
- Add safer server command UI.

Deferred:

- Full WebAuthn/passkey second-factor login.
- File transfer in Web v3.
- Audio, camera, terminal, and advanced remote tools.

## Web v3 Product Plan

Project name: QT Desk Web v3

Purpose:

- Replace the fragile old WebClient path with a clean, self-owned, professional web remote-control experience.
- Keep compatibility with RustDesk self-host server/API login.
- Make share links, admin control, logging, and security first-class features.

### V3 Principles

- Secure by default.
- Fast to open from admin device rows.
- Clear session states: preparing, connecting, connected, reconnecting, disconnected, expired, revoked.
- No long-lived admin token in the WebClient page.
- Admin can audit and revoke web sessions.
- Frontend is maintainable and separate from old v1/v2 assets.
- Backend response schemas are stable and documented.

### V3 Backend APIs

New API namespace:

- `POST /api/web-v3/session`
- `GET /api/web-v3/session/:session_id`
- `POST /api/web-v3/session/:session_id/refresh`
- `POST /api/web-v3/session/:session_id/revoke`
- `POST /api/web-v3/ws-token`
- `POST /api/web-v3/shared-peer`
- `GET /api/web-v3/config`

Admin API namespace:

- `POST /api/admin/web-v3/share`
- `GET /api/admin/web-v3/share/list`
- `POST /api/admin/web-v3/share/revoke`
- `GET /api/admin/web-v3/session/list`
- `POST /api/admin/web-v3/session/revoke`
- `GET /api/admin/web-v3/audit/list`
- `GET /api/admin/web-v3/settings`
- `POST /api/admin/web-v3/settings`

Backend session creation input:

- Peer ID mode: `{ "peer_id": "123456789" }`
- Share mode: `{ "share_token": "..." }`

Backend session output:

- `session_id`
- `peer_id`
- `peer_name`
- `peer_platform`
- `rendezvous_server`
- `relay_server`
- `public_key`
- `ws_token`
- `permissions`
- `expires_at`
- `ice_or_relay_policy`

### V3 Security Model

Tokens:

- Admin token only creates a web session.
- Web session token is short-lived.
- WebSocket token is even shorter-lived and scoped to one peer/session.
- Share token can be once-only or fixed, with expiration.

Permissions:

- `view`
- `control_mouse`
- `control_keyboard`
- `clipboard_read`
- `clipboard_write`
- `file_transfer`
- `terminal`
- `audio`
- `camera`

Defaults:

- Share links default to `view + control_mouse + control_keyboard`.
- File transfer disabled by default.
- Terminal disabled by default.
- Expiration default: 1 hour.

Audit events:

- Session created.
- WS token issued.
- Connect attempt.
- Connected.
- Disconnected.
- Reconnect.
- Share created.
- Share used.
- Share revoked.
- Permission denied.
- Token expired.
- File transfer attempt.

### V3 Frontend App

Path:

- `/web3/`

Supported URLs:

- `/web3/#/?id=123456789`
- `/web3/#/?share_token=...`
- `/web3/#/?session_id=...`

First usable MVP:

- Session bootstrap.
- Connection status UI.
- Remote canvas.
- Mouse input.
- Keyboard input.
- Clipboard buttons.
- Reconnect button.
- Error states.
- Expired/revoked states.

Better-than-v2 target features:

- Fast connect from admin device list.
- Clean toolbar with only necessary controls.
- Per-session permission display.
- Copy share link in one click.
- Fullscreen and fit-to-screen.
- Quality selector.
- FPS/latency indicator.
- Reconnect without leaving the page.
- Clear offline/permission/password errors.
- Safe clipboard prompts.
- Session expiry countdown.
- Admin-visible session identity.

Future advanced features:

- File transfer panel.
- Multi-monitor selector.
- Remote resolution selector.
- Audio toggle.
- Terminal tab.
- Screenshot capture.
- Recording disabled by default, admin-configurable only.
- Mobile responsive control mode.

### V3 Admin Integration

Devices page actions:

- Open App
- Web v3
- Share Web
- Copy Link
- Save to Address Book

Address Book page actions:

- Web v3
- Share Web
- Copy Link
- Edit saved credentials
- Tags and collection management

Share modal:

- Peer ID and hostname.
- Password input or saved password selection.
- Expiration selector.
- Once/fixed token selector.
- Permission toggles.
- Copy after create.
- Revoke existing shares.

Logs page:

- Web sessions.
- Web shares.
- Connection audit.
- Login logs.
- File audit.

Settings page:

- Enable Web v3.
- Default share expiration.
- Max session duration.
- Allow file transfer.
- Allow clipboard.
- Allow terminal.
- Require login for Web v3 direct peer mode.
- Allow share-token anonymous access.

### V3 Implementation Phases

Phase 1: Protocol and backend skeleton

- Add `docs/web-v3-protocol.md`.
- Add request/response structs.
- Add API routes.
- Create session and token tables/models.
- Add audit events.
- Keep old `/webclient` untouched.

Phase 2: Admin share flow

- Add `/api/admin/web-v3/share`.
- Add share modal in admin.
- Add Web v3 buttons on devices and address book.
- Add share list and revoke actions.

Phase 3: Frontend shell

- Create `rustdesk-api/resources/web3`.
- Build static HTML/CSS/JS app.
- Add session bootstrap and error screens.
- Add polished remote-control layout.

Phase 4: Remote connection MVP

- Reuse or adapt existing RustDesk web protocol pieces where legally available.
- Connect using backend config and scoped ws token.
- Render remote frames to canvas.
- Send mouse and keyboard events.
- Show latency and reconnect state.

Phase 5: Clipboard and quality

- Add clipboard read/write controls.
- Add quality/FPS selector.
- Add fullscreen and fit modes.
- Add mobile-friendly controls.

Phase 6: File transfer and advanced tools

- Add file transfer after MVP is stable.
- Add permission-gated terminal/audio/camera only if backend and protocol support are clear.
- Add admin policy controls.

Phase 7: Hardening and deployment

- Add integration tests where practical.
- Add Docker build verification.
- Update README and deployment docs.
- Add GitHub Actions image build/push.

## Next Prompt Recommendation

Suggested next prompt:

> Read `PROJECT_STATUS.md` first. Continue QT-DESK Web v3 Phase 4 and admin hardening. Docker stack is running with public `21114` and private admin `127.0.0.1:21124`; public `/web3/` and `/api/web-v3/config` return 200 while public `/_admin/` returns 404. Web v3 has direct YUV rendering, bottom command menu, quality/FPS monitor, desktop-only draggable expanded menu, reconnect/stall diagnostics, and video black-frame diagnostics. Admin now has redesigned Dashboard, Web Access, Backup/Restore, Custom Clients, and Deployment pages. Do a real logged-in browser pass with the current admin password, retest live remote image/input/YUV tearing/monitor metrics, verify draggable menu with a physical mouse, then continue polishing dedicated Devices/Users/Address Book pages and Web v3 settings persistence.
