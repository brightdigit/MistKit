#!/bin/bash
set -euo pipefail

# Only run in Claude Code on the web.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SWIFT_VERSION="6.1"
SWIFT_TAG="swift-${SWIFT_VERSION}-RELEASE"
SWIFT_DIR_NAME="${SWIFT_TAG}-ubuntu24.04"
SWIFT_INSTALL_DIR="${HOME}/.swift/${SWIFT_DIR_NAME}"
SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2404/${SWIFT_TAG}/${SWIFT_DIR_NAME}.tar.gz"

MISE_DIR="${HOME}/.local/share/mise"
MISE_BIN="${HOME}/.local/bin/mise"

ENV_FILE="${CLAUDE_ENV_FILE:-/dev/null}"

log() { echo "[session-start] $*"; }

# 1. System dependencies for Swift on Ubuntu 24.04.
if ! dpkg -s libcurl4-openssl-dev >/dev/null 2>&1; then
  log "Installing Swift system dependencies via apt..."
  export DEBIAN_FRONTEND=noninteractive
  # Tolerate failures from third-party PPAs; the packages we need live in the main Ubuntu repos.
  apt-get update -qq || true
  apt-get install -y --no-install-recommends \
    binutils \
    curl \
    git \
    gnupg2 \
    libc6-dev \
    libcurl4-openssl-dev \
    libedit2 \
    libgcc-13-dev \
    libpython3-dev \
    libsqlite3-0 \
    libstdc++-13-dev \
    libxml2-dev \
    libz3-dev \
    pkg-config \
    tzdata \
    unzip \
    zlib1g-dev
fi

# 2. Swift toolchain (matches Package.swift's swift-tools-version 6.1).
if [ ! -x "${SWIFT_INSTALL_DIR}/usr/bin/swift" ]; then
  log "Downloading Swift ${SWIFT_VERSION} toolchain..."
  mkdir -p "${HOME}/.swift"
  TMP_TAR="$(mktemp --suffix=.tar.gz)"
  curl -fsSL "${SWIFT_URL}" -o "${TMP_TAR}"
  tar -xzf "${TMP_TAR}" -C "${HOME}/.swift"
  rm -f "${TMP_TAR}"
fi

export PATH="${SWIFT_INSTALL_DIR}/usr/bin:${PATH}"

# 3. mise for the project's Swift tooling (swift-format, swiftlint, periphery, openapi-generator).
if [ ! -x "${MISE_BIN}" ]; then
  log "Installing mise..."
  mkdir -p "${HOME}/.local/bin"
  curl -fsSL https://mise.run | MISE_INSTALL_PATH="${MISE_BIN}" sh
fi

export PATH="${HOME}/.local/bin:${PATH}"
export MISE_DATA_DIR="${MISE_DIR}"

log "Installing project tools via mise..."
"${MISE_BIN}" trust "${CLAUDE_PROJECT_DIR}/mise.toml" >/dev/null 2>&1 || true
"${MISE_BIN}" install -C "${CLAUDE_PROJECT_DIR}"

# 4. Persist PATH and tool env into the session.
{
  echo "export PATH=\"${SWIFT_INSTALL_DIR}/usr/bin:${HOME}/.local/bin:\$PATH\""
  echo "export MISE_DATA_DIR=\"${MISE_DIR}\""
  "${MISE_BIN}" -C "${CLAUDE_PROJECT_DIR}" env -s bash
} >> "${ENV_FILE}"

log "Swift $(${SWIFT_INSTALL_DIR}/usr/bin/swift --version | head -1) ready."
log "Done."
