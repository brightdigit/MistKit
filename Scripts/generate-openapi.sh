#!/bin/bash

# Script to generate OpenAPI code
# This avoids using the build plugin which can cause friction for library consumers

set -e

echo "🔄 Generating OpenAPI code..."

# Get script directory and package directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PACKAGE_DIR="${SCRIPT_DIR}/.."

# Put mise-managed tools on PATH (swift-openapi-generator is provisioned via
# mise.toml). Skipped in Claude Code web sessions: mise resolves `spm:` tools
# through api.github.com, which those sessions cannot reach.
if command -v mise >/dev/null 2>&1 && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

pushd "$PACKAGE_DIR" || exit

# Prefer the mise-pinned binary. Where it is unavailable — Claude Code web
# sessions, or any checkout without mise — fall back to Scripts/OpenAPITools,
# a standalone manifest that pins the same generator version and resolves it
# over plain git (which those sessions can reach). Keeping the generator in
# its own manifest means it never enters MistKit's dependency graph, so the
# no-build-plugin decision above still holds.
#
# The version in Scripts/OpenAPITools/Package.swift must stay in sync with
# mise.toml's "spm:apple/swift-openapi-generator" pin.
if command -v swift-openapi-generator >/dev/null 2>&1; then
	GENERATOR=(swift-openapi-generator)
else
	echo "ℹ️  swift-openapi-generator not on PATH; building it from Scripts/OpenAPITools."
	GENERATOR=(swift run --package-path Scripts/OpenAPITools swift-openapi-generator)
fi

"${GENERATOR[@]}" generate \
    --output-directory Sources/MistKitOpenAPI \
    --config openapi-generator-config.yaml \
    openapi.yaml

popd

echo "✅ OpenAPI code generation complete!"
