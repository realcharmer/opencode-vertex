#!/usr/bin/env bash
set -euo pipefail

IMAGE="opencode-vertex"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "==> Checking prerequisites..."

if ! command -v docker &>/dev/null; then
  echo -e "${RED}Error: docker is not installed or not in PATH.${NC}"
  exit 1
fi

if ! docker info &>/dev/null; then
  echo -e "${RED}Error: Docker daemon is not running.${NC}"
  exit 1
fi

echo "==> Rebuilding Docker image: ${IMAGE} (no cache)..."
docker build --no-cache -t "${IMAGE}" "$(dirname "$0")"

echo ""
echo -e "${GREEN}Update complete. ${IMAGE} is now running the latest opencode release.${NC}"
