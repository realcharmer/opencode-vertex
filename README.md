# opencode-vertex

Run [opencode](https://opencode.ai) via Docker or Podman, using Google Vertex AI as the model provider. No local installation of opencode or the Google Cloud SDK required.

## Prebuilt image

Multi-arch images (`linux/amd64`, `linux/arm64`) are published to GitHub Container Registry:

```sh
docker pull ghcr.io/realcharmer/opencode-vertex:latest
```

Image tags mirror the upstream opencode release.

A scheduled workflow checks for new opencode releases and publishes a new image only when the version has changed.

## Setup

**1. Clone and run setup:**

```sh
./setup.sh
```

The script will:
- Auto-detect Podman or Docker (Podman is preferred if both are present)
- Pull the `opencode-vertex` image from GHCR
- Create two named volumes for persistent state
- Create `~/.config/opencode` on the host if it doesn't exist, for global skills/config
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
  --userns=keep-id \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace \
  -v opencode-gcloud:/gcloud \
  -v opencode-sessions:/sessions \
  -v "${HOME}/.config/opencode":/sessions/.config/opencode \
  --env-file "${HOME}/.opencode-vertex.env" \
  -e GOOGLE_APPLICATION_CREDENTIALS=/gcloud/application_default_credentials.json \
  -e HOME=/sessions \
  -e XDG_DATA_HOME=/sessions \
  -e XDG_CACHE_HOME=/sessions/.cache \
  -e OPENCODE_CONFIG=/etc/opencode/config.json \
  ghcr.io/realcharmer/opencode-vertex:latest'
```

Docker:
```sh
alias opencode='docker run -it --rm \
  --user "$(id -u):$(id -g)" \
  -v "$(pwd)":/workspace \
  -v opencode-gcloud:/gcloud \
  -v opencode-sessions:/sessions \
  -v "${HOME}/.config/opencode":/sessions/.config/opencode \
  --env-file "${HOME}/.opencode-vertex.env" \
  -e GOOGLE_APPLICATION_CREDENTIALS=/gcloud/application_default_credentials.json \
  -e HOME=/sessions \
  -e XDG_DATA_HOME=/sessions \
  -e XDG_CACHE_HOME=/sessions/.cache \
  -e OPENCODE_CONFIG=/etc/opencode/config.json \
  ghcr.io/realcharmer/opencode-vertex:latest'
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

Pull the latest published image:

```sh
./update.sh
```

Or manually:

Podman:
```sh
podman pull ghcr.io/realcharmer/opencode-vertex:latest
```

Docker:
```sh
docker pull ghcr.io/realcharmer/opencode-vertex:latest
```

### Building locally

```sh
docker build -t opencode-vertex .
```

To pin a specific opencode release instead of tracking `latest`:

```sh
docker build --build-arg OPENCODE_VERSION=v1.18.30 -t opencode-vertex .
```

Point your alias at `opencode-vertex` instead of the GHCR tag when using a local build.

## Agent Skills

The default shell alias mounts `~/.config/opencode` inside the container.
Create one folder per skill in `~/.config/opencode/skills` and put a SKILL.md inside it, for example:

```
~/.config/opencode/skills/<name>/SKILL.md
```

## Architecture

| Component | Details |
|---|---|
| Base image | `alpine:3.24` |
| opencode binary | musl build (native Alpine, no glibc shim) |
| Credentials | `opencode-gcloud` volume, mounted at `/gcloud` |
| Sessions | `opencode-sessions` volume, mounted at `/sessions` (`HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`) |
| Global config & skills | Host `~/.config/opencode`, mounted at `/sessions/.config/opencode` (matches remapped `$HOME`) |
| Project files | Mounted from `$(pwd)` at `/workspace` |
| Container runtime | Podman or Docker (auto-detected) |

Supports `x86_64` and `aarch64`.
The Dockerfile selects the correct musl binary automatically via `uname -m`.
