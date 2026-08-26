#!/bin/bash
set -euo pipefail

# SessionStart hook: install a Swift toolchain for Claude Code on the web
# (Linux). Only runs in remote sessions; local sessions are untouched. Runs
# async so the session starts immediately: progress lands in
# ~/.claude-session-setup.log and ~/.claude-session-setup.done marks the end.
#
# The toolchain is all this installs. Lint tooling is deliberately left out to
# keep cold start short: swift-format ships inside the toolchain, and both
# SwiftLint and periphery are skipped in web sessions (Scripts/lint.sh omits
# them when CLAUDE_CODE_REMOTE is set). Run `make lint` locally, where mise
# provides the pinned versions, to get full coverage.
#
# This hook is the second tier of a two-tier setup. The first tier is
# Scripts/cloud-setup.sh, pasted into the cloud environment's "Setup script"
# field: it runs once, then the filesystem is snapshotted and later sessions
# reuse it, so the ~1 GB toolchain download happens once per environment
# instead of once per container. When that snapshot exists, the `command -v
# swift` check below short-circuits and this hook finishes in about a second.
#
# The hook is still required on every session for two reasons: a snapshot
# restores files but not environment variables, so PATH has to be re-exported
# into CLAUDE_ENV_FILE each time; and an environment with no setup script
# configured (a fresh clone, another contributor) still needs the toolchain
# installed from here.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

echo '{"async": true, "asyncTimeout": 2400000}'

SETUP_LOG="$HOME/.claude-session-setup.log"
SETUP_DONE="$HOME/.claude-session-setup.done"
rm -f "$SETUP_DONE"
exec >> "$SETUP_LOG" 2>&1

SWIFTLY_ENV="$HOME/.local/share/swiftly/env.sh"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# Make swift reachable for the session up front; an entry pointing at a
# not-yet-populated directory is harmless.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo "export SWIFTLY_HOME_DIR=\"$HOME/.local/share/swiftly\""
    echo "export SWIFTLY_BIN_DIR=\"$HOME/.local/share/swiftly/bin\""
    echo "export PATH=\"$HOME/.local/share/swiftly/bin:\$PATH\""
  } >> "$CLAUDE_ENV_FILE"
fi

install_swift() {
  # System dependencies for Swift on Ubuntu 24.04 (per swift.org Linux
  # instructions), plus curl for fetching swiftly. Most are already in the
  # base image, so only reach for apt when something is genuinely missing --
  # `apt-get update` alone costs ~10s.
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

  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Installing missing system packages: ${missing[*]}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq --no-install-recommends "${missing[@]}"
  else
    echo "All system packages already present; skipping apt."
  fi

  # Install swiftly non-interactively, then the toolchain pinned by the
  # repo's .swift-version (falling back to latest if no pin resolves).
  local workdir
  workdir="$(mktemp -d)"
  pushd "$workdir" > /dev/null
  curl -fsSLO "https://download.swift.org/swiftly/linux/swiftly-$(uname -m).tar.gz"
  tar zxf "swiftly-$(uname -m).tar.gz"
  ./swiftly init -y --skip-install
  popd > /dev/null
  rm -rf "$workdir"

  # shellcheck disable=SC1090
  . "$SWIFTLY_ENV"

  cd "$PROJECT_DIR"
  if ! swiftly install -y; then
    echo "Pinned toolchain install failed; falling back to latest." >&2
    swiftly install -y latest
    swiftly use -y latest
  fi
}

# Pick up a swiftly install from a previous (cached) hook run.
if [ -f "$SWIFTLY_ENV" ]; then
  # shellcheck disable=SC1090
  . "$SWIFTLY_ENV"
fi

if command -v swift > /dev/null 2>&1; then
  echo "Swift already installed: $(swift --version 2>&1 | head -1)"
else
  install_swift
fi

swift --version
touch "$SETUP_DONE"
