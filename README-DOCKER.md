# Hardened Dragonfly Container Image

A highly secure, hardened, and multi-architecture (`amd64` and `arm64`) Docker image for **Dragonfly**—a modern, ultra-fast in-memory data store designed as a drop-in replacement for Redis and Memcached.

This image is built using a secure two-stage process. The final runtime image is based on `dhi.io/alpine-base:3.24`, which is optimized to contain **no package managers** (such as `apk`) or extraneous shell utilities (like `curl` or `wget`), significantly reducing the container's attack surface.

---

## Features

- **Hardened Base:** Built on top of a package-manager-less base image.
- **Multi-Architecture Support:** Built for both `linux/amd64` and `linux/arm64` (AArch64).
- **Lightweight:** Contains only the precompiled Dragonfly executable.

---

## Quick Start

Run Dragonfly immediately using Docker:

```bash
docker run -d --name dragonfly -p 6379:6379 hmtanbir/dragonfly:latest
```

To persist data, mount a volume to `/data` and configure Dragonfly to store snapshots there:

```bash
docker run -d \
  --name dragonfly \
  -p 6379:6379 \
  -v dragonfly_data:/data \
  hmtanbir/dragonfly:latest --logtostderr --dir=/data
```

---

## Using Docker Compose

Create a `docker-compose.yml` file:

```yaml
services:
  dragonfly:
    image: hmtanbir/dragonfly:latest
    container_name: dragonfly
    ports:
      - "6379:6379"
    volumes:
      - dragonfly_data:/data
    command: ["--logtostderr", "--dir=/data"]
    restart: unless-stopped

volumes:
  dragonfly_data:
```

Run with:

```bash
docker compose up -d
```

---

## Configuration Flags

Dragonfly accepts standard Redis-compatible and Dragonfly-specific flags as arguments. For example:

- `--dir=/data`: Directory to save database snapshots.
- `--logtostderr`: Route logs to stderr.
- `--requirepass=<YOUR_PASSWORD>`: Set an authentication password.
