#!/usr/bin/env bash
set -euo pipefail

IMAGE="opencode-vertex"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Detect container runtime: prefer Docker (if daemon is running), else Podman
# ---------------------------------------------------------------------------
detect_runtime() {
  if command -v podman &>/dev/null && podman info &>/dev/null 2>&1; then
    echo "podman"
  elif command -v docker &>/dev/null && docker info &>/dev/null 2>&1; then
    echo "docker"
  else
    echo ""
  fi
}

echo "==> Checking prerequisites..."

RUNTIME=$(detect_runtime)

if [[ -z "${RUNTIME}" ]]; then
  echo -e "${RED}Error: neither Docker (with a running daemon) nor Podman was found.${NC}"
  echo "Install Docker (https://docs.docker.com/get-docker/) or Podman (https://podman.io/getting-started/installation)."
  exit 1
fi

echo "  Using runtime: ${RUNTIME}"

echo "==> Rebuilding image: ${IMAGE} (no cache)..."
"${RUNTIME}" build --no-cache -t "${IMAGE}" "$(dirname "$0")"

echo ""
echo -e "${GREEN}Update complete. ${IMAGE} is now running the latest opencode release.${NC}"
