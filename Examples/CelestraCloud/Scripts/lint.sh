#!/bin/bash

# Remove set -e to allow script to continue running
# set -e  # Exit on any error

ERRORS=0

run_command() {
		if [ "$LINT_MODE" = "STRICT" ]; then
				"$@" || ERRORS=$((ERRORS + 1))
		else
				"$@"
		fi
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

if [ "$LINT_MODE" = "NONE" ]; then
	exit
elif [ "$LINT_MODE" = "STRICT" ]; then
	SWIFTFORMAT_OPTIONS="--configuration .swift-format"
	SWIFTLINT_OPTIONS="--strict"
	STRINGSLINT_OPTIONS="--config .strict.stringslint.yml"
else 
	SWIFTFORMAT_OPTIONS="--configuration .swift-format"
	SWIFTLINT_OPTIONS=""
	STRINGSLINT_OPTIONS="--config .stringslint.yml"
fi

pushd $PACKAGE_DIR
run_command $MINT_CMD bootstrap -m Mintfile

if [ -z "$CI" ]; then
	run_command $MINT_RUN swift-format format $SWIFTFORMAT_OPTIONS  --recursive --parallel --in-place Sources Tests
	run_command $MINT_RUN swiftlint --fix
fi

if [ -z "$FORMAT_ONLY" ]; then
	run_command $MINT_RUN swift-format lint --configuration .swift-format --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests
	run_command $MINT_RUN swiftlint lint $SWIFTLINT_OPTIONS
	# Check for compilation errors
	run_command swift build --build-tests
fi

$PACKAGE_DIR/Scripts/header.sh -d  $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "CelestraCloud"

# Generated files now automatically include ignore directives via OpenAPI generator configuration

if [ -z "$CI" ]; then
	run_command $MINT_RUN periphery scan $PERIPHERY_OPTIONS --disable-update-check
fi

popd

# Exit with error code if any errors occurred
if [ $ERRORS -gt 0 ]; then
	echo "Linting completed with $ERRORS error(s)"
	exit 1
else
	echo "Linting completed successfully"
	exit 0
fi
