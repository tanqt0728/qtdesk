# Docker Publishing

This repository includes a GitHub Actions workflow for building the server and
API images.

Workflow:

```text
.github/workflows/docker-images.yml
```

## Registry

The workflow publishes to Docker Hub:

```text
tanqt11/rustdesk-selfhost-qt-server
tanqt11/rustdesk-selfhost-qt-api
```

It publishes:

- `latest` on the default branch
- branch tags
- git tag refs such as `v1.0.0`
- `sha-<commit>` tags

Pull requests build images without pushing them.

## Docker Hub Secrets

Docker Hub publishing requires both repository secrets:

```text
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
```

## Compose Image Names

The compose defaults match the public image names:

```env
SERVER_IMAGE=tanqt11/rustdesk-selfhost-qt-server:latest
API_IMAGE=tanqt11/rustdesk-selfhost-qt-api:latest
```

## Before Publishing

Run:

```powershell
powershell -ExecutionPolicy Bypass -File tools\check-public-ready.ps1
```

Then verify the GitHub Actions run in the repository UI.
