#!/usr/bin/env bash
#
# SessionStart hook — provision the Swift toolchain and the pinned project
# tooling so Claude Code on the web sessions can run swift build / swift test /
# swift-format / swiftlint / periphery without manual setup.
#
# No-op for local sessions (CLAUDE_CODE_REMOTE unset). Idempotent: a warm
# container re-runs this in seconds.

set -uo pipefail

[ "${CLAUDE_CODE_REMOTE:-}" = "true" ] || exit 0

# The root Package.swift declares swift-tools-version 6.1, but
# Examples/MistDemo declares 6.2 — installing 6.1 makes the example packages
# unbuildable ("package is using Swift tools version 6.2.0 but the installed
# version is 6.1.0"). Install the highest tools-version any package in the
# repo requires; a newer toolchain still builds the older manifests.
readonly SWIFT_VERSION="6.2"
readonly SWIFT_RELEASE="swift-${SWIFT_VERSION}-RELEASE"
# download.swift.org spells the platform two different ways: the URL path
# segment is dotless ("ubuntu2404") while the archive/extracted directory name
# keeps the dot ("ubuntu24.04"). Using one for both yields a 404.
readonly SWIFT_PLATFORM="ubuntu24.04"
readonly SWIFT_PLATFORM_PATH="ubuntu2404"
readonly SWIFT_DIR="${HOME}/.swift"
readonly SWIFT_ROOT="${SWIFT_DIR}/${SWIFT_RELEASE}-${SWIFT_PLATFORM}"
readonly SWIFT_URL="https://download.swift.org/swift-${SWIFT_VERSION}-release/${SWIFT_PLATFORM_PATH}/${SWIFT_RELEASE}/${SWIFT_RELEASE}-${SWIFT_PLATFORM}.tar.gz"

log() { printf '[session-start] %s\n' "$*" >&2; }

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

# 1. Swift runtime dependencies. Third-party PPAs in the base image can fail
#    `apt-get update`; that must not abort provisioning, hence the `|| true`.
install_apt_dependencies() {
  if [ -f "${SWIFT_DIR}/.apt-done" ]; then
    log "apt dependencies already installed, skipping"
    return 0
  fi
  log "installing Swift runtime apt dependencies"
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -qq || true
  $SUDO apt-get install -y -qq --no-install-recommends \
    binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev \
    libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev \
    libz3-dev pkg-config tzdata unzip zlib1g-dev curl ca-certificates ||
    log "WARNING: some apt packages failed to install; continuing"
  mkdir -p "${SWIFT_DIR}" && touch "${SWIFT_DIR}/.apt-done"
}

# 2. Swift toolchain.
install_swift() {
  if [ -x "${SWIFT_ROOT}/usr/bin/swift" ]; then
    log "Swift ${SWIFT_VERSION} already present at ${SWIFT_ROOT}"
    return 0
  fi
  log "downloading Swift ${SWIFT_VERSION}"
  mkdir -p "${SWIFT_DIR}"
  local archive="${SWIFT_DIR}/${SWIFT_RELEASE}-${SWIFT_PLATFORM}.tar.gz"
  if ! curl -fsSL --retry 3 --retry-delay 2 -o "${archive}" "${SWIFT_URL}"; then
    log "ERROR: failed to download Swift toolchain"
    return 1
  fi
  log "extracting toolchain"
  if ! tar -xzf "${archive}" -C "${SWIFT_DIR}"; then
    log "ERROR: extraction failed"
    return 1
  fi
  rm -f "${archive}"
  if [ ! -x "${SWIFT_ROOT}/usr/bin/swift" ]; then
    log "ERROR: swift binary missing after extract"
    return 1
  fi
}

# 3. mise + the tools pinned in mise.toml (swift-format, swiftlint, periphery,
#    swift-openapi-generator). The spm: backends build from source, so the
#    toolchain has to be on PATH before this runs.
install_mise() {
  if ! command -v mise >/dev/null 2>&1 && [ ! -x "${HOME}/.local/bin/mise" ]; then
    log "installing mise"
    curl -fsSL https://mise.run | sh || {
      log "WARNING: mise install failed"
      return 0
    }
  else
    log "mise already installed"
  fi
  export PATH="${HOME}/.local/bin:${SWIFT_ROOT}/usr/bin:${PATH}"
  if [ -f "${CLAUDE_PROJECT_DIR:-.}/mise.toml" ]; then
    log "running mise install (the slow step on a cold container)"
    (cd "${CLAUDE_PROJECT_DIR:-.}" && mise install -y) ||
      log "WARNING: mise install reported errors"
  fi
}

# 4. Persist PATH for the rest of the session.
persist_environment() {
  local path_line="export PATH=\"${SWIFT_ROOT}/usr/bin:${HOME}/.local/bin:\${PATH}\""
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    if ! grep -qF "${SWIFT_ROOT}/usr/bin" "${CLAUDE_ENV_FILE}" 2>/dev/null; then
      printf '%s\n' "${path_line}" >>"${CLAUDE_ENV_FILE}"
    fi
    log "persisted PATH to CLAUDE_ENV_FILE"
  fi
  # Also land it in the shell profile so plain non-login shells inherit it.
  for profile in "${HOME}/.bashrc" "${HOME}/.profile"; do
    [ -f "${profile}" ] || continue
    if ! grep -qF "${SWIFT_ROOT}/usr/bin" "${profile}" 2>/dev/null; then
      printf '%s\n' "${path_line}" >>"${profile}"
    fi
  done
}

install_apt_dependencies
# Never block the session on a provisioning failure — the agent can still read
# and edit code, it just cannot build.
install_swift || exit 0
install_mise
persist_environment

export PATH="${SWIFT_ROOT}/usr/bin:${HOME}/.local/bin:${PATH}"
log "provisioning complete: $(swift --version 2>&1 | head -1)"
exit 0
