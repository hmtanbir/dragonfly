# Step 1: Use a temporary build image to download and extract the binary
FROM dhi.io/debian-base:trixie-debian13-dev AS builder

# Install curl, ca-certificates, tar, and binutils (for stripping binaries)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    tar \
    binutils \
    && rm -rf /var/lib/apt/lists/*

# Set Dragonfly version to download
ARG DRAGONFLY_VERSION=1.39.0

# Automatically populated by Buildx
ARG TARGETARCH

# Download, extract, rename, and set execution permissions based on build architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        ARCH="x86_64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        ARCH="aarch64"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi \
    && curl -L -s "https://github.com/dragonflydb/dragonfly/releases/download/v${DRAGONFLY_VERSION}/dragonfly-${ARCH}.tar.gz" | tar -xzf - \
    && mv dragonfly-${ARCH} /dragonfly \
    && chmod +x /dragonfly

# Copy Dragonfly binary and its exact dynamic glibc dependencies to a staging directory, and strip them to optimize size
RUN mkdir -p /staging/usr/local/bin \
    && cp /dragonfly /staging/usr/local/bin/dragonfly \
    && strip --strip-unneeded /staging/usr/local/bin/dragonfly \
    && for lib in $(ldd /dragonfly | grep -o '/[^ ]*'); do \
         mkdir -p "/staging$(dirname "$lib")"; \
         cp -L "$lib" "/staging$lib"; \
         strip --strip-unneeded "/staging$lib" || true; \
       done


# Step 2: Extract the hardened Alpine base image
FROM dhi.io/alpine-base:3.24 AS alpine-base

# Step 3: Combine and clean up symlinks to ensure the real glibc loader is used
FROM dhi.io/debian-base:trixie-debian13-dev AS combiner
COPY --from=alpine-base / /rootfs/
RUN rm -f /rootfs/lib/ld-linux-* /rootfs/lib64/ld-linux-*

# Remove shells from runtime stage to prevent execution
RUN rm -f /rootfs/bin/sh /rootfs/bin/ash

COPY --from=builder /staging/ /rootfs/

# Step 4: Build the final hardened image from scratch
FROM scratch
COPY --from=combiner /rootfs/ /

# Expose standard port and set entrypoint
EXPOSE 6379
ENTRYPOINT ["/usr/local/bin/dragonfly"]
