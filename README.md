# opencode-vertex

Run [opencode](https://opencode.ai) via Docker or Podman, using Google Vertex AI as the model provider. No local installation of opencode or the Google Cloud SDK required.

## Setup

**1. Clone and run setup:**

```sh
./setup.sh
```

The script will:
- Auto-detect Podman or Docker (Podman is preferred if both are present)
- Build the `opencode-vertex` image
- Create two named volumes for persistent state
- Automatically run the one-time Google Cloud login if credentials are not yet present

**2. Edit your env file:**

```sh
# ~/.opencode-vertex.env
GOOGLE_CLOUD_PROJECT=your-project-id
VERTEX_LOCATION=global
```

**3. Add alias to your shell config**:

Podman:
```sh
alias opencode='podman run -it --rm \
  -v "$(pwd)":/workspace \
  -v opencode-gcloud:/root/.config/gcloud \
  -v opencode-sessions:/root/.local/share/opencode \
  --env-file "${HOME}/.opencode-vertex.env" \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
  opencode-vertex'
```

Docker:
```sh
alias opencode='docker run -it --rm \
  -v "$(pwd)":/workspace \
  -v opencode-gcloud:/root/.config/gcloud \
  -v opencode-sessions:/root/.local/share/opencode \
  --env-file "${HOME}/.opencode-vertex.env" \
  -e GOOGLE_APPLICATION_CREDENTIALS=/root/.config/gcloud/application_default_credentials.json \
  opencode-vertex'
```

`setup.sh` prints the exact alias for you (using whichever runtime was detected), so you can copy it directly.

Then open a new session or reload your shell:

```sh
source ~/.bashrc
```

## Authentication

`setup.sh` handles authentication automatically. On first run it launches a `google/cloud-sdk:alpine` container, prompts you to complete the OAuth flow in your browser, then removes the container. Credentials are saved to the `opencode-gcloud` volume and persist indefinitely (the refresh token does not expire unless explicitly revoked).

On subsequent runs of `setup.sh`, existing credentials are detected and the login step is skipped.

To re-authenticate manually at any time (e.g. after revoking access):

Podman:
```sh
podman run -it --rm \
  -v opencode-gcloud:/root/.config/gcloud \
  google/cloud-sdk:alpine \
  gcloud auth application-default login
```

Docker:
```sh
docker run -it --rm \
  -v opencode-gcloud:/root/.config/gcloud \
  google/cloud-sdk:alpine \
  gcloud auth application-default login
```

## Usage

Navigate to any project directory and run:

```sh
opencode
```

It behaves as if opencode were installed locally. Sessions are persisted across container runs in the `opencode-sessions` volume.

## Updating

Rebuild the image to pull the latest opencode release:

```sh
./update.sh
```

Or manually:

Podman:
```sh
podman build --no-cache -t opencode-vertex .
```

Docker:
```sh
docker build --no-cache -t opencode-vertex .
```

## Architecture

| Component | Details |
|---|---|
| Base image | `alpine:3.21` |
| opencode binary | musl build (native Alpine, no glibc shim) |
| Credentials | `opencode-gcloud` volume |
| Sessions | `opencode-sessions` volume |
| Project files | Mounted from `$(pwd)` at `/workspace` |
| Container runtime | Podman or Docker (auto-detected) |

Supports `x86_64` and `aarch64`.
The Dockerfile selects the correct musl binary automatically via `uname -m`.
