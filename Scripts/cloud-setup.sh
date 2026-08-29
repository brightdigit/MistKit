#!/bin/bash

# Setup script for Claude Code on the web (cloud environments).
#
# Paste this into the environment dialog's "Setup script" field at
# claude.ai/code. It is committed here so the content stays reviewable and
# versioned, but the platform reads it from that dialog, not from the repo.
#
# Why here and not in the SessionStart hook: a setup script runs once per
# environment, then Anthropic snapshots the filesystem and reuses that snapshot
# for later sessions, which skip the script entirely. SessionStart hooks re-run
# on every session and get no such caching. The Swift toolchain is a ~1 GB
# download, so it belongs in the snapshot.
#
# .claude/hooks/session-start.sh stays as the fallback: it installs the same
# toolchain when an environment has no setup script configured, and on every
# session it wires PATH into CLAUDE_ENV_FILE (a filesystem snapshot restores
# files, not environment variables).
#
# Requirements this script is written around:
#   * Must exit 0 -- a non-zero exit makes the session fail to start.
#   * Must finish inside ~5 minutes or the environment cache will not build.
#     Measured cold install is ~2 minutes.
#   * Runs as root on Ubuntu 24.04, before Claude Code launches.
#   * Needs download.swift.org on the environment's allowed-domains list
#     (Network access: Custom, with the default package-manager list included).

# No `set -e`: every failure path has to fall through to `exit 0` so a bad
# install degrades to the SessionStart hook rather than bricking the session.
set -uo pipefail

# Used only when no .swift-version can be found on disk. Keep in sync with the
# repo's .swift-version.
FALLBACK_SWIFT_VERSION="6.3.2"

SWIFTLY_ENV="$HOME/.local/share/swiftly/env.sh"

log() {
  # stderr, not stdout: resolve_swift_version's value is read via command
  # substitution, so any stdout chatter would be captured into the version.
  echo "[cloud-setup] $*" >&2
}

# The setup script may run before the repository is checked out, and the
# checkout path is not contractual, so look in the likely places and fall back
# to the pinned literal above rather than failing.
resolve_swift_version() {
  local candidate
  for candidate in \
    "${CLAUDE_PROJECT_DIR:-/nonexistent}/.swift-version" \
    "$PWD/.swift-version" \
    /home/user/*/.swift-version \
    /workspace/*/.swift-version \
    /root/*/.swift-version; do
    if [ -f "$candidate" ]; then
      local version
      version="$(tr -d '[:space:]' < "$candidate")"
      if [ -n "$version" ]; then
        log "Using Swift $version pinned by $candidate"
        printf '%s' "$version"
        return 0
      fi
    fi
  done
  log "No .swift-version found; falling back to Swift $FALLBACK_SWIFT_VERSION"
  printf '%s' "$FALLBACK_SWIFT_VERSION"
}

# System dependencies for Swift on Ubuntu 24.04 (per swift.org's Linux
# instructions), plus curl for fetching swiftly. Most are already in the base
# image, so only reach for apt when something is genuinely missing: apt-get
# update alone costs ~10s and pulls in unrelated upgrades.
install_system_packages() {
  local packages missing pkg
  packages=(
    binutils
    curl
    git
    gnupg2
    libc6-dev
    libcurl4-openssl-dev
    libedit2
    libgcc-13-dev
    libncurses-dev
    libpython3-dev
    libsqlite3-0
    libstdc++-13-dev
    libxml2-dev
    libz3-dev
    pkg-config
    tzdata
    zlib1g-dev
  )
  missing=()
  for pkg in "${packages[@]}"; do
    if [ "$(dpkg-query -W -f='${db:Status-Status}' "$pkg" 2> /dev/null)" != "installed" ]; then
      missing+=("$pkg")
    fi
  done

  if [ "${#missing[@]}" -eq 0 ]; then
    log "All system packages already present; skipping apt."
    return 0
  fi

  log "Installing missing system packages: ${missing[*]}"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq || return 1
  apt-get install -y -qq --no-install-recommends "${missing[@]}" || return 1
}

install_swiftly() {
  local workdir
  workdir="$(mktemp -d)" || return 1
  (
    cd "$workdir" || exit 1
    curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz" || exit 1
    tar zxf "swiftly-$(uname -m).tar.gz" || exit 1
    ./swiftly init -y --skip-install || exit 1
  )
  local status=$?
  rm -rf "$workdir"
  return "$status"
}

# Make swift resolvable for plain login shells too. This is a file, so the
# environment snapshot carries it; the SessionStart hook still handles
# CLAUDE_ENV_FILE for Claude Code's own process.
write_profile_entry() {
  cat > /etc/profile.d/swiftly.sh <<'PROFILE'
# Added by MistKit Scripts/cloud-setup.sh
export SWIFTLY_HOME_DIR="$HOME/.local/share/swiftly"
export SWIFTLY_BIN_DIR="$HOME/.local/share/swiftly/bin"
case ":$PATH:" in
  *":$SWIFTLY_BIN_DIR:"*) ;;
  *) export PATH="$SWIFTLY_BIN_DIR:$PATH" ;;
esac
PROFILE
}

main() {
  if [ -f "$SWIFTLY_ENV" ]; then
    # shellcheck disable=SC1090
    . "$SWIFTLY_ENV"
  fi

  if command -v swift > /dev/null 2>&1; then
    log "Swift already installed: $(swift --version 2>&1 | head -1)"
    write_profile_entry
    return 0
  fi

  local version
  version="$(resolve_swift_version)"

  install_system_packages || {
    log "WARNING: system package install failed; continuing anyway."
  }

  install_swiftly || {
    log "ERROR: swiftly install failed."
    return 1
  }

  # shellcheck disable=SC1090
  . "$SWIFTLY_ENV" || return 1

  if ! swiftly install -y "$version"; then
    log "Pinned toolchain $version failed to install; falling back to latest."
    swiftly install -y latest || return 1
    swiftly use -y latest || return 1
  else
    swiftly use -y "$version" || return 1
  fi

  write_profile_entry
  swift --version
}

if main; then
  log "Setup complete."
else
  log "Setup did not complete; the SessionStart hook will install Swift instead."
fi

# Always succeed: a non-zero exit here stops the session from starting.
exit 0
