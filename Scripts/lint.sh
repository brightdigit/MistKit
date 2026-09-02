#!/bin/bash

# Remove set -e to allow script to continue running
# set -e  # Exit on any error

# Report mode (read-only, structured output for humans and agents):
#   LINT_REPORT=1    human summary on stderr + JSON between delimiter markers
#   LINT_REPORT=json JSON report only (delimiters on stdout)
#
# Exit code is non-zero when any pipeline step fails. Each lint tool runs with
# --strict so warnings/findings fail their step. summary.totalFindings in the
# JSON counts individual findings across tools (must be 0 for a clean run).

ERRORS=0
FAILED_STEP_NAMES=()
LINT_REPORT_MODE=0
LINT_REPORT_OUTPUT=""
REPORT_DIR=""
MANIFEST_PATH=""

run_command() {
	"$@" || ERRORS=$((ERRORS + 1))
}

record_failed_step() {
	local step="$1"
	FAILED_STEP_NAMES+=("$step")
}

log_status() {
	if [ "$LINT_REPORT_MODE" -eq 1 ]; then
		echo "$@" >&2
	else
		echo "$@"
	fi
}

run_report_step() {
	local step="$1"
	shift
	local exit_code=0

	"$@"
	exit_code=$?

	if [ "$exit_code" -ne 0 ]; then
		ERRORS=$((ERRORS + 1))
		record_failed_step "$step"
	fi

	printf '%s' "$exit_code" >"$REPORT_DIR/${step}.exit"
	return "$exit_code"
}

init_report_mode() {
	case "${LINT_REPORT:-}" in
	1 | yes | true | TRUE | YES)
		LINT_REPORT_OUTPUT=both
		LINT_REPORT_MODE=1
		;;
	json | JSON)
		LINT_REPORT_OUTPUT=json
		LINT_REPORT_MODE=1
		;;
	*)
		LINT_REPORT_OUTPUT=""
		LINT_REPORT_MODE=0
		;;
	esac

	if [ "$LINT_REPORT_MODE" -eq 1 ]; then
		REPORT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/mistkit-lint-report.XXXXXX")
		MANIFEST_PATH="$REPORT_DIR/manifest.json"
	fi
}

cleanup_report_mode() {
	if [ -n "$REPORT_DIR" ] && [ -d "$REPORT_DIR" ]; then
		rm -rf "$REPORT_DIR"
	fi
}

write_manifest() {
	local swiftlint_skipped="${1:-0}"
	local swiftlint_skip_reason="${2:-}"
	local periphery_skipped="${3:-0}"
	local periphery_skip_reason="${4:-}"
	local swift_build_skipped="${5:-0}"
	local swift_build_skip_reason="${6:-}"
	local failed_steps_csv=""

	if [ "${#FAILED_STEP_NAMES[@]}" -gt 0 ]; then
		local IFS=,
		failed_steps_csv="${FAILED_STEP_NAMES[*]}"
	fi

	REPORT_DIR="$REPORT_DIR" \
		MANIFEST_PATH="$MANIFEST_PATH" \
		LINT_REPORT_OUTPUT="$LINT_REPORT_OUTPUT" \
		FAILED_STEPS_CSV="$failed_steps_csv" \
		SWIFTLINT_SKIPPED="$swiftlint_skipped" \
		SWIFTLINT_SKIP_REASON="$swiftlint_skip_reason" \
		PERIPHERY_SKIPPED="$periphery_skipped" \
		PERIPHERY_SKIP_REASON="$periphery_skip_reason" \
		SWIFT_BUILD_SKIPPED="$swift_build_skipped" \
		SWIFT_BUILD_SKIP_REASON="$swift_build_skip_reason" \
		python3 - <<'PY'
import json
import os
from pathlib import Path

report_dir = Path(os.environ["REPORT_DIR"])
manifest_path = Path(os.environ["MANIFEST_PATH"])
failed_steps = [
    step for step in os.environ.get("FAILED_STEPS_CSV", "").split(",") if step
]


def read_exit(step: str) -> int | None:
    exit_path = report_dir / f"{step}.exit"
    if not exit_path.is_file():
        return None
    return int(exit_path.read_text(encoding="utf-8"))


manifest = {
    "reportDir": str(report_dir),
    "outputFormat": os.environ["LINT_REPORT_OUTPUT"],
    "failedSteps": failed_steps,
    "steps": {
        "swift-format": {"exitCode": read_exit("swift-format")},
        "swiftlint": {
            "skipped": os.environ.get("SWIFTLINT_SKIPPED") == "1",
            "skipReason": os.environ.get("SWIFTLINT_SKIP_REASON") or None,
            "exitCode": read_exit("swiftlint"),
        },
        "swift-build": {
            "skipped": os.environ.get("SWIFT_BUILD_SKIPPED") == "1",
            "skipReason": os.environ.get("SWIFT_BUILD_SKIP_REASON") or None,
            "exitCode": read_exit("swift-build"),
        },
        "periphery": {
            "skipped": os.environ.get("PERIPHERY_SKIPPED") == "1",
            "skipReason": os.environ.get("PERIPHERY_SKIP_REASON") or None,
            "exitCode": read_exit("periphery"),
        },
    },
}
manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
PY
}

emit_lint_report() {
	local swiftlint_skipped="$1"
	local swiftlint_skip_reason="$2"
	local periphery_skipped="$3"
	local periphery_skip_reason="$4"
	local swift_build_skipped="$5"
	local swift_build_skip_reason="$6"

	write_manifest \
		"$swiftlint_skipped" "$swiftlint_skip_reason" \
		"$periphery_skipped" "$periphery_skip_reason" \
		"$swift_build_skipped" "$swift_build_skip_reason"

	python3 "$PACKAGE_DIR/.claude/skills/fix-lint/scripts/compile-lint-report.py" "$MANIFEST_PATH"
}

if [ "$LINT_MODE" = "INSTALL" ]; then
	exit
fi

init_report_mode
trap cleanup_report_mode EXIT

echo "LintMode: $LINT_MODE" >&2
if [ "$LINT_REPORT_MODE" -eq 1 ]; then
	echo "LintReport: $LINT_REPORT_OUTPUT (read-only)" >&2
fi

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
fi

SWIFTFORMAT_FORMAT_OPTIONS="--configuration .swift-format"
SWIFTFORMAT_LINT_OPTIONS="--configuration .swift-format --strict"
SWIFTLINT_OPTIONS="--strict"
PERIPHERY_OPTIONS="--strict"

SWIFTLINT_SKIP_REASON=""
PERIPHERY_SKIP_REASON=""
SWIFT_BUILD_SKIP_REASON=""

pushd "$PACKAGE_DIR" >/dev/null || exit

if [ -z "$CI" ] && [ "$LINT_REPORT_MODE" -eq 0 ]; then
	run_command swift-format format $SWIFTFORMAT_FORMAT_OPTIONS --recursive --parallel --in-place Sources Tests
	if [ "$RUN_SWIFTLINT" -eq 1 ]; then
		run_command swiftlint --fix
	fi
fi

if [ -z "$FORMAT_ONLY" ] || [ "$LINT_REPORT_MODE" -eq 1 ]; then
	if [ "$LINT_REPORT_MODE" -eq 1 ]; then
		run_report_step swift-format \
			swift-format lint --recursive --parallel \
			$SWIFTFORMAT_LINT_OPTIONS Sources Tests \
			>"$REPORT_DIR/swift-format.log" 2>&1
	else
		run_command swift-format lint --recursive --parallel \
			$SWIFTFORMAT_LINT_OPTIONS Sources Tests
	fi

	if [ "$RUN_SWIFTLINT" -eq 1 ]; then
		if [ "$LINT_REPORT_MODE" -eq 1 ]; then
			run_report_step swiftlint \
				swiftlint lint --quiet --reporter json $SWIFTLINT_OPTIONS \
				>"$REPORT_DIR/swiftlint.json" 2>"$REPORT_DIR/swiftlint.stderr"
		else
			run_command swiftlint lint $SWIFTLINT_OPTIONS
		fi
	else
		SWIFTLINT_SKIP_REASON="Claude Code web session"
		if [ "$LINT_REPORT_MODE" -eq 0 ]; then
			echo "Skipping SwiftLint (Claude Code web session)."
		fi
	fi

	if [ "$LINT_REPORT_MODE" -eq 1 ]; then
		run_report_step swift-build \
			swift build --build-tests \
			>"$REPORT_DIR/swift-build.log" 2>&1
	else
		run_command swift build --build-tests
	fi
fi

if [ "$LINT_REPORT_MODE" -eq 1 ]; then
	if ! "$PACKAGE_DIR/Scripts/header.sh" -d "$PACKAGE_DIR/Sources" -c "Leo Dion" -o "BrightDigit" -p "MistKit" >&2; then
		ERRORS=$((ERRORS + 1))
		record_failed_step header
	fi
else
	"$PACKAGE_DIR/Scripts/header.sh" -d "$PACKAGE_DIR/Sources" -c "Leo Dion" -o "BrightDigit" -p "MistKit"
fi

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

if { [ -z "$FORMAT_ONLY" ] || [ "$LINT_REPORT_MODE" -eq 1 ]; } \
	&& [ -z "$CI" ] && [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
	if INDEX_STORE_PATH=$(periphery_index_store); then
		if [ "$LINT_REPORT_MODE" -eq 1 ]; then
			run_report_step periphery \
				periphery scan $PERIPHERY_OPTIONS \
				--index-store-path "$INDEX_STORE_PATH" --skip-build \
				--disable-update-check --format json --quiet \
				>"$REPORT_DIR/periphery.json" 2>"$REPORT_DIR/periphery.stderr"
		else
			run_command periphery scan $PERIPHERY_OPTIONS \
				--index-store-path "$INDEX_STORE_PATH" --skip-build \
				--disable-update-check
		fi
	else
		PERIPHERY_SKIP_REASON="no index store under .build; run swift build first"
		if [ "$LINT_REPORT_MODE" -eq 0 ]; then
			echo "Skipping periphery scan ($PERIPHERY_SKIP_REASON)."
		fi
	fi
else
	if [ -n "$CI" ]; then
		PERIPHERY_SKIP_REASON="CI"
	elif [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
		PERIPHERY_SKIP_REASON="Claude Code web session"
	fi
	if [ "$LINT_REPORT_MODE" -eq 0 ]; then
		echo "Skipping periphery scan (${PERIPHERY_SKIP_REASON:-CI or Claude Code web session})."
	fi
fi

if [ "$LINT_REPORT_MODE" -eq 1 ]; then
	swiftlint_skipped=0
	if [ "$RUN_SWIFTLINT" -eq 0 ]; then
		swiftlint_skipped=1
	fi
	periphery_skipped=0
	if [ -n "$PERIPHERY_SKIP_REASON" ]; then
		periphery_skipped=1
	fi
	swift_build_skipped=0
	emit_lint_report \
		"$swiftlint_skipped" "$SWIFTLINT_SKIP_REASON" \
		"$periphery_skipped" "$PERIPHERY_SKIP_REASON" \
		"$swift_build_skipped" "$SWIFT_BUILD_SKIP_REASON"
fi

popd >/dev/null

# Exit with error code if any errors occurred
if [ $ERRORS -gt 0 ]; then
	log_status "Linting completed with $ERRORS error(s)"
	exit 1
else
	log_status "Linting completed successfully"
	exit 0
fi
