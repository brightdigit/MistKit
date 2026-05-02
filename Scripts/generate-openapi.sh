#!/bin/bash

# Script to generate OpenAPI code
# This avoids using the build plugin which can cause friction for library consumers

set -e

echo "🔄 Generating OpenAPI code..."

# Get script directory and package directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PACKAGE_DIR="${SCRIPT_DIR}/.."

# Put mise-managed tools on PATH (swift-openapi-generator is provisioned via mise.toml)
if command -v mise >/dev/null 2>&1; then
	eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

pushd $PACKAGE_DIR

swift-openapi-generator generate \
    --output-directory Sources/MistKit/Generated \
    --config openapi-generator-config.yaml \
    openapi.yaml

popd

echo "✅ OpenAPI code generation complete!"
