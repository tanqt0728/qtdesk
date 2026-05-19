# Security Policy

## Public Deployment Defaults

For cloud hosting, expose only the public API/Web v3 listener unless you have a private network in front of the admin console.

Recommended split mode:

```sh
docker compose --env-file .env \
  -f docker-compose.yml \
  -f docker-compose.windows.yml \
  -f docker-compose.admin-split.yml \
  up -d
```

In split mode:

- Public API/Web v3: `21114`
- Private admin UI/API: `21124` by default

Bind `21124` only to localhost, VPN, Tailscale/ZeroTier, SSH tunnel, or a reverse proxy with IP allowlisting and HTTPS.

## Secrets That Must Not Be Published

Do not commit:

- `.env`
- SQLite databases
- backup zip files
- OAuth client secrets
- JWT secrets
- server private keys
- signing certificates
- admin tokens
- browser test profiles

Rotate any secret that appeared in chat, screenshots, logs, or a public repository.

## Server Keys

The RustDesk server private key controls trust for clients. Treat `/server-data/id_ed25519` or `/root/data/id_ed25519` as sensitive.

Backup export may include server keys for migration. Store backup files offline and delete temporary copies.

## Admin Account

After first boot:

- Change the default admin password.
- Prefer OAuth/OIDC with strong identity provider controls.
- Keep password login disabled only after OAuth is confirmed working.
- Put admin access behind VPN or IP allowlist.

## Reporting

For now, report vulnerabilities through the GitHub issue tracker after removing secrets and private host details from logs/screenshots.
