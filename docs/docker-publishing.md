# Docker Publishing

This repository includes a GitHub Actions workflow for building the server and
API images.

Workflow:

```text
.github/workflows/docker-images.yml
```

## Default Registry

GitHub Container Registry is enabled by default:

```text
ghcr.io/<github-owner>/rustdesk-selfhost-qt-server
ghcr.io/<github-owner>/rustdesk-selfhost-qt-api
```

The workflow publishes:

- `latest` on the default branch
- branch tags
- git tag refs such as `v1.0.0`
- `sha-<commit>` tags

Pull requests build images without pushing them.

## Optional Docker Hub

Docker Hub publishing is enabled only when both repository secrets are set:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

When those secrets exist, the same workflow also publishes:

```text
tanqt11/rustdesk-selfhost-qt-server
tanqt11/rustdesk-selfhost-qt-api
```

## Compose Image Names

The compose defaults match the public image names:

```env
SERVER_IMAGE=tanqt11/rustdesk-selfhost-qt-server:latest
API_IMAGE=tanqt11/rustdesk-selfhost-qt-api:latest
```

For GHCR images:

```env
SERVER_IMAGE=ghcr.io/<github-owner>/rustdesk-selfhost-qt-server:latest
API_IMAGE=ghcr.io/<github-owner>/rustdesk-selfhost-qt-api:latest
```

## Before Publishing

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-public-ready.ps1
```

Then verify the GitHub Actions run in the repository UI.
