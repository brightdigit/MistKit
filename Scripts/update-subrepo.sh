#!/bin/bash
set -e

# Generic script to update any example subrepo
# Usage: ./Scripts/update-subrepo.sh Examples/BushelCloud
#        ./Scripts/update-subrepo.sh Examples/Celestra

if [ $# -eq 0 ]; then
    echo "Usage: $0 <subrepo-path>"
    echo "Example: $0 Examples/BushelCloud"
    exit 1
fi

SUBREPO_PATH="$1"
SUBREPO_NAME=$(basename "$SUBREPO_PATH")

if [ ! -d "$SUBREPO_PATH" ]; then
    echo "❌ Error: Directory $SUBREPO_PATH does not exist"
    exit 1
fi

if [ ! -f "$SUBREPO_PATH/.gitrepo" ]; then
    echo "❌ Error: $SUBREPO_PATH is not a git subrepo (missing .gitrepo file)"
    exit 1
fi

echo "🔄 Updating $SUBREPO_NAME subrepo..."
echo ""

# Extract current branch from .gitrepo
CURRENT_BRANCH=$(grep -E '^\s*branch\s*=' "$SUBREPO_PATH/.gitrepo" | sed 's/.*=\s*//')
echo "📍 Current branch: $CURRENT_BRANCH"

# Pull latest from subrepo
echo ""
echo "📥 Pulling latest from remote..."
git subrepo pull "$SUBREPO_PATH" --branch="$CURRENT_BRANCH"

# Handle local MistKit dependencies (for BushelCloud and CelestraCloud)
echo ""
echo "🔄 Checking for local MistKit dependencies..."
if grep -q '\.package(name: "MistKit", path:' "$SUBREPO_PATH/Package.swift"; then
    echo "✓ Found local MistKit dependency - preserving for local development"
else
    echo "✓ No local MistKit dependency found"
fi

# Resolve dependencies
echo ""
echo "📦 Resolving Swift package dependencies..."
cd "$SUBREPO_PATH"
swift package resolve

# Build to verify
echo ""
echo "🔨 Building to verify changes..."
swift build

# Go back to project root
cd - > /dev/null

echo ""
echo "✅ Update complete!"
echo ""
echo "📊 Subrepo status:"
cat "$SUBREPO_PATH/.gitrepo" | grep -E "commit|branch|remote"

echo ""
echo "🎯 Next steps:"
echo "  1. Review changes: git diff $SUBREPO_PATH/"
echo "  2. Run tests: cd $SUBREPO_PATH && swift test"
echo "  3. Commit changes: git add $SUBREPO_PATH && git commit -m 'Update $SUBREPO_NAME subrepo'"
