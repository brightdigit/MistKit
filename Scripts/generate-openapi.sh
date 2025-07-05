#!/bin/bash

# Script to generate OpenAPI code
# This avoids using the build plugin which can cause friction for library consumers

set -e

echo "🔄 Generating OpenAPI code..."

# Run the OpenAPI generator
swift run swift-openapi-generator generate \
    --output-directory Sources/MistKit/Generated \
    --config openapi-generator-config.yaml \
    openapi.yaml

echo "✅ OpenAPI code generation complete!"