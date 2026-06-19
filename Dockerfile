# syntax=docker/dockerfile:1
FROM alpine:3.21

# Install runtime dependencies
# - ca-certificates: TLS verification for API calls
# - libstdc++: required by the opencode binary (Bun runtime)
# - git: opencode uses git for project context
RUN apk add --no-cache ca-certificates libstdc++ git

# Download and install the correct opencode musl binary for the build arch.
# uname -m works with both the legacy builder and BuildKit.
RUN set -eux; \
    ARCH="$(uname -m)"; \
    case "${ARCH}" in \
        x86_64)  ASSET="opencode-linux-x64-musl.tar.gz" ;; \
        aarch64) ASSET="opencode-linux-arm64-musl.tar.gz" ;; \
        *) echo "Unsupported architecture: ${ARCH}" && exit 1 ;; \
    esac; \
    wget -qO /tmp/opencode.tar.gz \
        "https://github.com/anomalyco/opencode/releases/latest/download/${ASSET}"; \
    tar -xzf /tmp/opencode.tar.gz -C /tmp/; \
    mv /tmp/opencode /usr/local/bin/opencode; \
    chmod 755 /usr/local/bin/opencode; \
    rm /tmp/opencode.tar.gz

# Bake in the provider configuration
COPY opencode.json /root/.config/opencode/config.json

WORKDIR /workspace

ENTRYPOINT ["opencode"]
