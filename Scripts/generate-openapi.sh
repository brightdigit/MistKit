#!/bin/bash

# Script to generate OpenAPI code
# This avoids using the build plugin which can cause friction for library consumers

set -e

echo "🔄 Generating OpenAPI code..."

# Get script directory and package directory
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PACKAGE_DIR="${SCRIPT_DIR}/.."

# Detect OS and set paths accordingly
if [ "$(uname)" = "Darwin" ]; then
	DEFAULT_MINT_PATH="/opt/homebrew/bin/mint"
elif [ "$(uname)" = "Linux" ] && [ -n "$GITHUB_ACTIONS" ]; then
	DEFAULT_MINT_PATH="$GITHUB_WORKSPACE/Mint/.mint/bin/mint"
elif [ "$(uname)" = "Linux" ]; then
	DEFAULT_MINT_PATH="/usr/local/bin/mint"
else
	echo "Unsupported operating system"
	exit 1
fi

# Use environment MINT_CMD if set, otherwise use default path
MINT_CMD=${MINT_CMD:-$DEFAULT_MINT_PATH}

export MINT_PATH="$PACKAGE_DIR/.mint"
MINT_ARGS="-n -m $PACKAGE_DIR/Mintfile --silent"
MINT_RUN="$MINT_CMD run $MINT_ARGS"

pushd $PACKAGE_DIR
$MINT_CMD bootstrap -m Mintfile

# Run the OpenAPI generator via Mint
$MINT_RUN swift-openapi-generator generate \
    --output-directory Sources/MistKit/Generated \
    --config openapi-generator-config.yaml \
    openapi.yaml

popd

echo "✅ OpenAPI code generation complete!"