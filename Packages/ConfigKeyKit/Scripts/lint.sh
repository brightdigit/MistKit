#!/bin/bash

# Remove set -e to allow script to continue running

ERRORS=0

run_command() {
	"$@" || ERRORS=$((ERRORS + 1))
}

if [ "$LINT_MODE" = "INSTALL" ]; then
	exit
fi

echo "LintMode: $LINT_MODE"

# More portable way to get script directory
if [ -z "$SRCROOT" ]; then
	SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
	PACKAGE_DIR="${SCRIPT_DIR}/.."
else
	PACKAGE_DIR="${SRCROOT}"
fi

# Ensure mise-managed tools are on PATH outside CI (CI uses jdx/mise-action)
if command -v mise >/dev/null 2>&1 && [ -z "$CI" ]; then
	eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

if [ "$LINT_MODE" = "NONE" ]; then
	exit
elif [ "$LINT_MODE" = "STRICT" ]; then
	SWIFTFORMAT_OPTIONS="--configuration .swift-format"
	SWIFTLINT_OPTIONS="--strict"
else
	SWIFTFORMAT_OPTIONS="--configuration .swift-format"
	SWIFTLINT_OPTIONS=""
fi

pushd $PACKAGE_DIR

if [ -z "$CI" ]; then
	run_command swift-format format $SWIFTFORMAT_OPTIONS --recursive --parallel --in-place Sources Tests
	run_command swiftlint --fix
fi

if [ -z "$FORMAT_ONLY" ]; then
	run_command swift-format lint --configuration .swift-format --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests
	run_command swiftlint lint $SWIFTLINT_OPTIONS
	run_command swift build --build-tests
fi

$PACKAGE_DIR/Scripts/header.sh -d $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "ConfigKeyKit"

if [ -z "$CI" ]; then
	run_command periphery scan $PERIPHERY_OPTIONS --disable-update-check
fi

popd

if [ $ERRORS -gt 0 ]; then
	echo "Linting completed with $ERRORS error(s)"
	exit 1
else
	echo "Linting completed successfully"
	exit 0
fi
