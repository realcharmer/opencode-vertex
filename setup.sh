#!/usr/bin/env bash
set -euo pipefail

IMAGE="opencode-vertex"
ENV_FILE="${HOME}/.opencode-vertex.env"
GCLOUD_VOLUME="opencode-gcloud"
SESSIONS_VOLUME="opencode-sessions"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Create ~/.opencode-vertex.env if it doesn't exist
if [[ ! -f "${ENV_FILE}" ]]; then
  echo -e "${YELLOW}No env file found at ${ENV_FILE}.${NC}"
  cp "$(dirname "$0")/.env.example" "${ENV_FILE}"
  echo -e "Created ${ENV_FILE} from .env.example."
  echo -e "${YELLOW}Please edit ${ENV_FILE} and set your GOOGLE_CLOUD_PROJECT, then re-run setup.sh.${NC}"
  exit 0
fi

# Warn if GOOGLE_CLOUD_PROJECT is still the placeholder
if grep -q "your-project-id" "${ENV_FILE}"; then
  echo -e "${YELLOW}Warning: GOOGLE_CLOUD_PROJECT in ${ENV_FILE} still has the placeholder value.${NC}"
  echo -e "Edit ${ENV_FILE} and set your real project ID before using opencode."
fi

echo "==> Building Docker image: ${IMAGE}..."
docker build -t "${IMAGE}" "$(dirname "$0")"

echo "==> Creating Docker volumes (if not already present)..."
docker volume create "${GCLOUD_VOLUME}" &>/dev/null && echo "  Volume ${GCLOUD_VOLUME} ready."
docker volume create "${SESSIONS_VOLUME}" &>/dev/null && echo "  Volume ${SESSIONS_VOLUME} ready."

# Check whether application default credentials already exist in the volume
CREDS_PATH="/root/.config/gcloud/application_default_credentials.json"
CREDS_EXIST=$(docker run --rm \
  -v "${GCLOUD_VOLUME}:/root/.config/gcloud" \
  alpine \
  sh -c "[ -f '${CREDS_PATH}' ] && echo yes || echo no" 2>/dev/null)

if [[ "${CREDS_EXIST}" != "yes" ]]; then
  echo ""
  echo "==> No Google Cloud credentials found. Running one-time login..."
  LOGIN_CONTAINER="opencode-gcloud-login-$$"
  cleanup_login_container() {
    docker rm -f "${LOGIN_CONTAINER}" &>/dev/null || true
  }
  trap cleanup_login_container EXIT

  docker run -it \
    --name "${LOGIN_CONTAINER}" \
    -v "${GCLOUD_VOLUME}:/root/.config/gcloud" \
    google/cloud-sdk:alpine \
    gcloud auth application-default login

  cleanup_login_container
  trap - EXIT
  echo -e "${GREEN}Login successful.${NC}"
else
  echo "  Existing Google Cloud credentials detected — skipping login."
fi

# Detect current shell config file
detect_shell_config() {
  local shell
  shell=$(basename "${SHELL:-bash}")
  case "${shell}" in
    zsh)  echo "${HOME}/.zshrc" ;;
    bash) echo "${HOME}/.bashrc" ;;
    *)    echo "${HOME}/.profile" ;;
  esac
}

SHELL_CONFIG=$(detect_shell_config)

echo ""
echo -e "${GREEN}Setup complete.${NC}"
echo ""
echo "-----------------------------------------------------------------------"
echo " Add the following alias to ${SHELL_CONFIG}:"
echo "-----------------------------------------------------------------------"
echo ""
echo "alias opencode='docker run -it --rm \\"
echo "  -v \"\$(pwd)\":/workspace \\"
echo "  -v ${GCLOUD_VOLUME}:/root/.config/gcloud \\"
echo "  -v ${SESSIONS_VOLUME}:/root/.local/share/opencode \\"
echo "  --env-file \"${ENV_FILE}\" \\"
echo "  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \\"
echo "  ${IMAGE}'"
echo ""
echo "Then run: source ${SHELL_CONFIG}"
echo "-----------------------------------------------------------------------"
