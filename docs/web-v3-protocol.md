# QT Desk Web v3 Protocol

Last updated: 2026-05-14

This document defines the first backend contract for QT Desk Web v3. Phase 1 is a protocol and API skeleton only: it creates stable routes, database models, and audit events while leaving the legacy `/webclient` path untouched.

## Goals

- Create short-lived web sessions without exposing long-lived admin or user tokens to the browser.
- Support two bootstrap modes:
  - direct peer mode for authenticated users or admins
  - share-token mode for anonymous share links
- Keep Web v3 state auditable from the admin dashboard.
- Leave room for the later remote-control transport, clipboard, file transfer, and policy layers.

## URL Entry Points

The future frontend will live at `/web3/` and support:

- `/web3/#/?id=123456789`
- `/web3/#/?share_token=...`
- `/web3/#/?session_id=...`

## Public API Namespace

All public Web v3 API routes are under `/api/web-v3`.

### `POST /api/web-v3/session`

Creates a Web v3 session.

Direct peer mode requires a normal RustDesk API bearer token:

```json
{
  "peer_id": "123456789"
}
```

Share mode accepts a short-lived share token:

```json
{
  "share_token": "qt_share_token"
}
```

Response:

```json
{
  "session_id": "uuid",
  "peer_id": "123456789",
  "peer_name": "Workstation",
  "peer_platform": "Windows",
  "rendezvous_server": "example.com",
  "relay_server": "example.com:21117",
  "public_key": "server-public-key",
  "ws_token": "short-lived-token",
  "permissions": ["view", "control_mouse", "control_keyboard"],
  "expires_at": 1778757600,
  "ice_or_relay_policy": "rustdesk-relay"
}
```

### `GET /api/web-v3/session/:session_id`

Returns non-secret session metadata and current state.

Session states:

- `preparing`
- `connecting`
- `connected`
- `reconnecting`
- `disconnected`
- `expired`
- `revoked`

### `POST /api/web-v3/session/:session_id/refresh`

Refreshes short-lived session activity and issues a new WebSocket token when the session is still valid.

### `POST /api/web-v3/session/:session_id/revoke`

Revokes a session.

### `POST /api/web-v3/ws-token`

Issues a short-lived WebSocket token scoped to one session and one peer.

Request:

```json
{
  "session_id": "uuid"
}
```

### `POST /api/web-v3/shared-peer`

Resolves a share token to peer metadata without creating a remote-control session. This is intended for preflight UI and validation.

Request:

```json
{
  "share_token": "qt_share_token"
}
```

### `GET /api/web-v3/config`

Returns server-side Web v3 bootstrap configuration:

```json
{
  "enabled": true,
  "rendezvous_server": "example.com",
  "relay_server": "example.com:21117",
  "public_key": "server-public-key",
  "default_permissions": ["view", "control_mouse", "control_keyboard"],
  "default_session_seconds": 3600,
  "default_ws_token_seconds": 300
}
```

## Admin API Namespace

All admin routes are under `/api/admin/web-v3` and require backend admin authentication.

- `POST /api/admin/web-v3/share`
- `GET /api/admin/web-v3/share/list`
- `POST /api/admin/web-v3/share/revoke`
- `GET /api/admin/web-v3/session/list`
- `POST /api/admin/web-v3/session/revoke`
- `GET /api/admin/web-v3/audit/list`
- `GET /api/admin/web-v3/settings`
- `POST /api/admin/web-v3/settings`

## Permissions

Known permission strings:

- `view`
- `control_mouse`
- `control_keyboard`
- `clipboard_read`
- `clipboard_write`
- `file_transfer`
- `terminal`
- `audio`
- `camera`

Default share permissions:

```json
["view", "control_mouse", "control_keyboard"]
```

## Token Model

- Admin or user token: only used to create a direct Web v3 session.
- Share token: short-lived, optionally once-only, scoped to one peer.
- WebSocket token: short-lived, scoped to one session and one peer.

Phase 1 stores token digests in the database. Raw tokens are only returned at creation time.

## Audit Events

Initial event names:

- `session_created`
- `ws_token_issued`
- `connect_attempt`
- `connected`
- `disconnected`
- `reconnect`
- `share_created`
- `share_used`
- `share_revoked`
- `permission_denied`
- `token_expired`
- `session_revoked`
- `file_transfer_attempt`

Each event stores the session ID, peer ID, user ID when known, source IP, user agent, and JSON details.

