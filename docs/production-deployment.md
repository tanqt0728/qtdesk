# Production Deployment

This guide covers the recommended public hosting shape for this repository.

## Network Shape

Use admin split mode for any server that is reachable from the internet.

Set the public server address in one place:

```env
QT_DESK_SERVER_HOST=rustdesk.example.com
RUSTDESK_ID_PUBLIC=${QT_DESK_SERVER_HOST}:21116
RUSTDESK_RELAY_PUBLIC=${QT_DESK_SERVER_HOST}:21117
RUSTDESK_API_PUBLIC_URL=http://${QT_DESK_SERVER_HOST}:21114
```

`100.x.x.x` addresses are normally private VPN/CGNAT-style addresses, so they
are good for Tailscale/WireGuard/private access. For a public internet server,
use a real public IP or DNS name instead.

- Public port `21114`: API endpoints needed by clients and Web v3.
- Private port `21124`: Web Admin and `/api/admin/*`.
- RustDesk server ports: expose only the ports your clients need.

Recommended public exposure:

```text
21115/tcp  NAT test
21116/tcp  ID server
21116/udp  ID server
21117/tcp  Relay server
21118/tcp  ID server WebSocket
21119/tcp  Relay server WebSocket
21114/tcp  Public API / Web v3
21124/tcp  Private only, never open to the whole internet
```

Web v3 note:

- Native RustDesk clients normally use `21116` and `21117`.
- Browser Web v3 uses WebSocket ports `21118` and `21119`.
- If you open Web v3 through a VPN/Tailscale admin address, the browser should
  stay on that reachable entrypoint for both rendezvous and relay WebSockets.
  Example: `http://100.x.x.x:21124/web3/` should connect to
  `ws://100.x.x.x:21118` and `ws://100.x.x.x:21119`.
- Do not put `21118` or `21119` into the legacy `custom-rendezvous-server` or
  `custom-relay-server` localStorage values manually; that legacy protocol
  stores native ports and adds `+2` internally.

Run split mode:

```sh
docker compose --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.windows.yml \
  -f docker-compose.admin-split.yml \
  up -d --build
```

In `.env`, keep the admin host port bound to localhost unless you put it behind
a trusted private network:

```env
RUSTDESK_API_ADMIN_ADDR=0.0.0.0:21124
RUSTDESK_API_ADMIN_HOST_PORT=127.0.0.1:21124
```

## Admin Access Options

Best options:

- SSH tunnel:

  ```sh
  ssh -L 21124:127.0.0.1:21124 user@your-server
  ```

  Then open:

  ```text
  http://127.0.0.1:21124/_admin/
  ```

- VPN or mesh network such as Tailscale, ZeroTier, WireGuard.
- Reverse proxy with HTTPS, IP allowlist, and ideally an extra auth layer.

Do not publish `21124` directly to the whole internet.

## Caddy Example

Public API/Web v3:

```caddyfile
rustdesk.example.com {
  encode zstd gzip

  reverse_proxy 127.0.0.1:21114
}
```

Private admin with an IP allowlist:

```caddyfile
admin.rustdesk.example.com {
  encode zstd gzip

  @allowed remote_ip 203.0.113.10 198.51.100.0/24
  handle @allowed {
    reverse_proxy 127.0.0.1:21124
  }

  respond "forbidden" 403
}
```

## Nginx Example

Public API/Web v3:

```nginx
server {
    listen 443 ssl http2;
    server_name rustdesk.example.com;

    ssl_certificate /etc/letsencrypt/live/rustdesk.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/rustdesk.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:21114;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

Private admin:

```nginx
server {
    listen 443 ssl http2;
    server_name admin.rustdesk.example.com;

    allow 203.0.113.10;
    allow 198.51.100.0/24;
    deny all;

    ssl_certificate /etc/letsencrypt/live/admin.rustdesk.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.rustdesk.example.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:21124;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Migration From Old lejianwen/rustdesk-api

If you can read the old SQLite database, create a selective backup zip offline:

```sh
python tools/export-legacy-rustdesk-api.py \
  --db /path/to/old/rustdeskapi.db \
  --out rustdesk-legacy-selected-backup.zip \
  --components users,address_book,devices
```

Then use the new admin Backup page:

1. `Inspect backup`
2. Confirm the detected components and counts.
3. `Smart import`

If the old deployment has no export feature and you only copied files by SFTP,
you can either zip the files directly or pack them into the standard import
shape:

```sh
python tools/pack-sftp-backup.py \
  --root /path/to/sftp-copy \
  --out rustdesk-sftp-backup.zip
```

The smart importer recognizes common SFTP zip layouts too, including:

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

If you also migrate `server_keys`, restart both services afterward:

```sh
docker compose --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.windows.yml \
  -f docker-compose.admin-split.yml \
  restart rustdesk-server rustdesk-api
```

## Pre-Publish Check

Before pushing publicly:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-public-ready.ps1
```

Rotate any secret that has appeared in screenshots, logs, chat, or git history.
