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
	STRINGSLINT_OPTIONS="--config .strict.stringslint.yml"
else
	SWIFTFORMAT_OPTIONS="--configuration .swift-format"
	SWIFTLINT_OPTIONS=""
	STRINGSLINT_OPTIONS="--config .stringslint.yml"
fi

pushd $PACKAGE_DIR

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

# Periphery does not run in Claude Code web sessions: it would have to be built
# from source there (no Linux binaries, and the session's GitHub gateway rules
# out mise), which is not worth the cold-start cost.
if [ -z "$CI" ] && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	run_command periphery scan $PERIPHERY_OPTIONS --disable-update-check
elif [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
	echo "Skipping periphery scan (Claude Code web session)."
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
