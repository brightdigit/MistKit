#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SWIFT_VERSION="6.3"
SWIFT_RELEASE="swift-${SWIFT_VERSION}-RELEASE"
SWIFT_PLATFORM="ubuntu24.04"
SWIFT_PLATFORM_DIR="ubuntu2404"
SWIFT_TARBALL="${SWIFT_RELEASE}-${SWIFT_PLATFORM}.tar.gz"
SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/${SWIFT_PLATFORM_DIR}/${SWIFT_RELEASE}/${SWIFT_TARBALL}"
SWIFT_HOME="${HOME}/.swift/${SWIFT_RELEASE}"
SWIFT_BIN="${SWIFT_HOME}/usr/bin"

LOCAL_BIN="${HOME}/.local/bin"
mkdir -p "${LOCAL_BIN}"

log() { echo "[session-start] $*"; }

# 1. Apt deps for Swift runtime on Ubuntu 24.04. Tolerate flaky third-party PPAs.
if ! dpkg -s libcurl4-openssl-dev >/dev/null 2>&1; then
  log "Installing apt dependencies"
  sudo apt-get update -qq || true
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    binutils \
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
    zlib1g-dev \
    curl \
    ca-certificates
else
  log "Apt dependencies already present"
fi

# 2. Swift 6.3 toolchain
if [ ! -x "${SWIFT_BIN}/swift" ]; then
  log "Downloading Swift ${SWIFT_VERSION} toolchain"
  mkdir -p "${HOME}/.swift"
  TMPDIR_SWIFT="$(mktemp -d)"
  trap 'rm -rf "${TMPDIR_SWIFT}"' EXIT
  curl -fsSL "${SWIFT_URL}" -o "${TMPDIR_SWIFT}/${SWIFT_TARBALL}"
  tar -xzf "${TMPDIR_SWIFT}/${SWIFT_TARBALL}" -C "${HOME}/.swift"
  rm -rf "${TMPDIR_SWIFT}"
  trap - EXIT
else
  log "Swift ${SWIFT_VERSION} already installed at ${SWIFT_HOME}"
fi

export PATH="${SWIFT_BIN}:${LOCAL_BIN}:${PATH}"

# 3. mise (cross-tool runtime manager)
if ! command -v mise >/dev/null 2>&1; then
  log "Installing mise"
  curl -fsSL https://mise.run | sh
fi

MISE_BIN="${HOME}/.local/bin/mise"
if [ ! -x "${MISE_BIN}" ]; then
  log "ERROR: mise install failed (${MISE_BIN} missing)"
  exit 1
fi

# 4. mise install (swift-format, swiftlint, periphery, swift-openapi-generator)
log "Running mise install"
cd "${CLAUDE_PROJECT_DIR}"
"${MISE_BIN}" trust --quiet mise.toml || true
"${MISE_BIN}" install

# 5. Persist PATH + mise activation for the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export PATH=\"${SWIFT_BIN}:${LOCAL_BIN}:\$PATH\""
    echo 'eval "$(${HOME}/.local/bin/mise activate bash --shims)"'
  } >> "${CLAUDE_ENV_FILE}"
fi

log "swift: $(swift --version 2>&1 | head -n1)"
log "mise:  $(${MISE_BIN} --version)"
log "Done."
