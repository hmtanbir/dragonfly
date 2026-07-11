# Hardened Dragonfly Container Image

This repository contains the configuration for building and deploying a hardened, multi-architecture Docker image for [Dragonfly](https://github.com/dragonflydb/dragonfly) (a modern, high-performance in-memory data store).

The image is optimized for security and production stability by utilizing a two-stage build that outputs into `dhi.io/alpine-base:3.24` (a hardened Alpine base image containing **no package manager** like `apk` or curl/wget).

---

## Repository Structure

- `Dockerfile`: Multi-stage, multi-architecture configuration supporting both `amd64` and `arm64`.
- `docker-compose.yml`: For locally building and running the service with volume-based persistence.
- `.github/workflows/deploy.yml`: GitHub Actions workflow that builds the multi-platform images and pushes them to Docker Hub.

---

## Dockerfile Design

The [Dockerfile](Dockerfile) uses a multi-stage approach to minimize the attack surface of the final image:

1. **Stage 1 (Builder):** Uses a standard `alpine:3.24` image to install build/extraction dependencies (`curl`, `tar`), check the target architecture (`TARGETARCH`), and download the matching official Dragonfly binary release.
2. **Stage 2 (Final):** Uses `dhi.io/alpine-base:3.24`. It copies **only** the compiled executable from the builder, ensuring there are no package managers, utilities, or extra tools left in the final production runtime container.

---

## Local Usage

### Prerequisites
- Docker & Docker Compose installed locally.

### Start Dragonfly Locally
To build the image and spin up the container with data persistence:

```bash
docker compose up -d --build
```

Dragonfly will now be available on port `6379`.

---

## Deployment & CI/CD (GitHub Actions)

A CI workflow is defined in [.github/workflows/deploy.yml](.github/workflows/deploy.yml).

### Workflow Features
- **Triggers:** Automatically runs on pushes to the `main` branch.
- **Platforms:** Builds multi-platform images (`linux/amd64` and `linux/arm64`) using Docker Buildx and QEMU.
- **Push Destination:** Pushes to Docker Hub under the username stored in repository secrets.
- **Tags:** Tags the built images as both `latest` and `1.39.0`.

### Required Repository Secrets
To run the GitHub Actions workflow successfully, add the following secrets in your GitHub repository settings under **Settings > Secrets and variables > Actions**:

- `DOCKERHUB_USERNAME`: Your Docker Hub username.
- `DOCKERHUB_TOKEN`: Your Docker Hub personal access token (recommended) or password.
