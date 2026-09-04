#!/bin/bash
set -e

# Generic script to update any example subrepo
# Usage: ./Scripts/update-subrepo.sh Examples/BushelCloud
#        ./Scripts/update-subrepo.sh Examples/CelestraCloud

if [ $# -eq 0 ]; then
    echo "Usage: $0 <subrepo-path>"
    echo "Example: $0 Examples/BushelCloud"
    exit 1
fi

SUBREPO_PATH="$1"
SUBREPO_NAME=$(basename "$SUBREPO_PATH")
REPO_ROOT="$(git rev-parse --show-toplevel)"

MISTKIT_URL_DEP='.package(url: "https://github.com/brightdigit/MistKit.git", from: "1.0.0-beta.4")'
MISTKIT_PATH_DEP='.package(name: "MistKit", path: "../..")'

restore_local_mistkit_path_dep() {
    local package_swift="$SUBREPO_PATH/Package.swift"

    if [ ! -f "$package_swift" ]; then
        return 0
    fi

    if grep -qF "$MISTKIT_URL_DEP" "$package_swift"; then
        echo "🔧 Restoring local MistKit path dependency for monorepo development..."
        if [ "$SUBREPO_NAME" = "BushelCloud" ]; then
            sed -i '' "s|$MISTKIT_URL_DEP|        // Local path: BushelCloud develops as Examples/BushelCloud inside the\\
        // MistKit repo, so ../.. resolves to the parent MistKit checkout. On main\\
        // this is a tagged remote release; this one-line overlay is reapplied when\\
        // the branch is recreated from main (never merged, so it never conflicts).\\
        $MISTKIT_PATH_DEP|" "$package_swift"
        else
            sed -i '' "s|$MISTKIT_URL_DEP|$MISTKIT_PATH_DEP|" "$package_swift"
        fi
    elif grep -q '\.package(name: "MistKit", path:' "$package_swift"; then
        echo "✓ Local MistKit path dependency already present"
    else
        echo "✓ No MistKit dependency to restore"
    fi
}

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
CURRENT_BRANCH=$(grep -E '^\s*branch\s*=' "$SUBREPO_PATH/.gitrepo" | sed 's/.*=\s*//' | tr -d '[:space:]')
echo "📍 Current branch: $CURRENT_BRANCH"

# Pull latest from subrepo; retry with --force after upstream squash invalidates .gitrepo commit
echo ""
echo "📥 Pulling latest from remote..."
set +e
PULL_OUTPUT=$(git subrepo pull "$SUBREPO_PATH" --branch="$CURRENT_BRANCH" 2>&1)
PULL_STATUS=$?
set -e

if [ "$PULL_STATUS" -ne 0 ]; then
    if echo "$PULL_OUTPUT" | grep -q 'Local repository does not contain'; then
        echo "⚠️  Stale subrepo commit reference detected; force-pulling from $CURRENT_BRANCH..."
        git subrepo pull "$SUBREPO_PATH" --force --branch="$CURRENT_BRANCH" --update \
            -m "Re-sync $SUBREPO_NAME subrepo after upstream branch squash"
    else
        echo "$PULL_OUTPUT"
        exit "$PULL_STATUS"
    fi
else
    echo "$PULL_OUTPUT"
fi

restore_local_mistkit_path_dep

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
cd "$REPO_ROOT"

echo ""
echo "✅ Update complete!"
echo ""
echo "📊 Subrepo status:"
grep -E "commit|branch|remote" "$SUBREPO_PATH/.gitrepo"

echo ""
echo "🎯 Next steps:"
echo "  1. Review changes: git diff $SUBREPO_PATH/"
echo "  2. Run tests: cd $SUBREPO_PATH && swift test"
echo "  3. Commit changes: git add $SUBREPO_PATH && git commit -m 'Update $SUBREPO_NAME subrepo'"
