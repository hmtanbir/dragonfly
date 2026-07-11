# Step 1: Use a temporary build image to download and extract the binary
FROM alpine:3.24 AS builder

# Install curl and tar to download/extract
RUN apk add --no-cache curl tar

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


# Step 2: Move the executable into the hardened base image (which lacks package managers)
FROM dhi.io/alpine-base:3.24

# Copy binary from builder
COPY --from=builder /dragonfly /usr/local/bin/dragonfly

# Expose standard port and set entrypoint
EXPOSE 6379
ENTRYPOINT ["/usr/local/bin/dragonfly"]
