#!/bin/bash

# Remove set -e to allow script to continue running
# set -e  # Exit on any error

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

# Ensure mise-managed tools are on PATH outside CI (CI uses jdx/mise-action).
# Skipped in Claude Code web sessions: mise resolves its `spm:`/`aqua:` tools
# through api.github.com, which those sessions cannot reach, so evaluating its
# env would only shadow the toolchain's own swift-format with a broken shim.
if command -v mise >/dev/null 2>&1 && [ -z "$CI" ] \
	&& [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	eval "$(mise -C "$PACKAGE_DIR" env -s bash)"
fi

# SwiftLint and periphery are not installed in Claude Code web sessions (no
# Linux binaries for periphery, and mise is unreachable per above). swift-format
# ships inside the Swift toolchain, so formatting, the header check and the
# build still run there; run ./Scripts/lint.sh locally for full coverage.
if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
	RUN_SWIFTLINT=0
else
	RUN_SWIFTLINT=1
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

pushd "$PACKAGE_DIR" || exit

if [ -z "$CI" ]; then
	run_command swift-format format $SWIFTFORMAT_OPTIONS  --recursive --parallel --in-place Sources Tests
	if [ "$RUN_SWIFTLINT" -eq 1 ]; then
		run_command swiftlint --fix
	fi
fi

if [ -z "$FORMAT_ONLY" ]; then
	run_command swift-format lint --configuration .swift-format --recursive --parallel $SWIFTFORMAT_OPTIONS Sources Tests
	if [ "$RUN_SWIFTLINT" -eq 1 ]; then
		run_command swiftlint lint $SWIFTLINT_OPTIONS
	else
		echo "Skipping SwiftLint (Claude Code web session)."
	fi
	# Check for compilation errors
	run_command swift build --build-tests
fi

$PACKAGE_DIR/Scripts/header.sh -d  $PACKAGE_DIR/Sources -c "Leo Dion" -o "BrightDigit" -p "MistKit"

# Generated files now automatically include ignore directives via OpenAPI generator configuration

# Periphery cannot find the index store on its own: its location depends on the
# build system. swiftbuild (the SwiftPM default since Swift 6.2) writes
# `.build/out`, the native build system writes
# `.build/<triple>/debug/index/store`, and older toolchains wrote
# `.build/debug/index/store`. Resolve it here and hand it over explicitly;
# `--index-store-path` implies `--skip-build`, which is what we want because
# `swift build --build-tests` already ran above. Skipped in CI (periphery has
# never run there) and in Claude Code web sessions (no Linux binaries; mise
# unreachable per above).
periphery_index_store() {
	local candidate
	for candidate in "$PACKAGE_DIR"/.build/*/debug/index/store \
		"$PACKAGE_DIR"/.build/debug/index/store \
		"$PACKAGE_DIR"/.build/out; do
		if [ -d "$candidate/v5/units" ]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done
	return 1
}

if [ -z "$CI" ] && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	if INDEX_STORE_PATH=$(periphery_index_store); then
		run_command periphery scan $PERIPHERY_OPTIONS \
			--index-store-path "$INDEX_STORE_PATH" --skip-build \
			--disable-update-check
	else
		echo "Skipping periphery scan (no index store under .build; run swift build first)."
	fi
else
	echo "Skipping periphery scan (CI or Claude Code web session)."
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
