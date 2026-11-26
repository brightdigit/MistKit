#!/bin/bash

# Refresh the CloudKit web-auth tokens used by the MistDemo Integration
# workflow (.github/workflows/MistDemo-Integration.yml) and store them as
# GitHub Actions secrets.
#
# Web-auth tokens expire; when they do, the "Live CloudKit Integration" job
# fails with HTTP 421 AUTHENTICATION_REQUIRED. This script:
#   1. loads CLOUDKIT_API_TOKEN / CLOUDKIT_CONTAINER_ID (and
#      CLOUDKIT_SHAREE_EMAIL) from a dotenv file,
#   2. builds and runs `mistdemo auth-tokens --output env` (or `auth-token`
#      with --single), which opens the browser for Apple ID sign-in,
#   3. pipes each captured value to `gh secret set` over stdin,
#   4. optionally rewrites the same keys in the env file and re-runs the
#      most recent failed MistDemo-Integration run for the current branch.
#
# Token values are never echoed and never passed on a command line.
#
# Usage: see usage() below or run with --help.

set -euo pipefail

REPO="brightdigit/MistKit"
WORKFLOW="MistDemo-Integration.yml"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MISTDEMO_DIR="$REPO_ROOT/Examples/MistDemo"

ENV_FILE="$REPO_ROOT/../MistDemo.env"
SINGLE=false
UPDATE_ENV=false
RERUN=false
DRY_RUN=false
SHAREE_EMAIL_ARG=""
ENVIRONMENT="development"

usage() {
	cat <<EOF
Usage: $0 [--env-file PATH] [--sharee-email EMAIL] [--single] [--update-env] [--rerun] [--dry-run] [--environment ENV]

Capture fresh CloudKit web-auth tokens via browser sign-in and save them as
GitHub secrets on $REPO.

  --env-file PATH       dotenv file with CLOUDKIT_API_TOKEN and
                        CLOUDKIT_CONTAINER_ID (default: ../MistDemo.env
                        relative to the repo root)
  --sharee-email EMAIL  sharee iCloud email (default: CLOUDKIT_SHAREE_EMAIL
                        from the env file); required unless --single
  --single              capture only the sharer token (mistdemo auth-token)
                        and set only CLOUDKIT_WEB_AUTH_TOKEN
  --update-env          also rewrite the captured keys in the env file
  --rerun               re-run the most recent failed $WORKFLOW run for the
                        current branch (failed jobs only)
  --dry-run             skip sign-in and print which secrets would be set
  --environment ENV     CloudKit environment (default: development, as CI uses)
  -h, --help            show this help

Environment overrides: MISTDEMO_BIN (prebuilt mistdemo binary; skips swift build).
EOF
}

die() {
	echo "❌ $*" >&2
	exit 1
}

info() {
	echo "→  $*" >&2
}

while [ $# -gt 0 ]; do
	case "$1" in
		--env-file)
			[ $# -ge 2 ] || die "--env-file requires a path"
			ENV_FILE="$2"
			shift 2
			;;
		--sharee-email)
			[ $# -ge 2 ] || die "--sharee-email requires a value"
			SHAREE_EMAIL_ARG="$2"
			shift 2
			;;
		--environment)
			[ $# -ge 2 ] || die "--environment requires a value"
			ENVIRONMENT="$2"
			shift 2
			;;
		--single) SINGLE=true; shift ;;
		--update-env) UPDATE_ENV=true; shift ;;
		--rerun) RERUN=true; shift ;;
		--dry-run) DRY_RUN=true; shift ;;
		-h | --help) usage; exit 0 ;;
		*) usage >&2; die "unknown argument: $1" ;;
	esac
done

[ -f "$ENV_FILE" ] || die "env file not found: $ENV_FILE (pass --env-file PATH)"

# Read KEY from a dotenv file without sourcing it (values are not shell-safe).
# The last assignment wins, matching dotenv loaders. Surrounding quotes are
# stripped. Prints nothing when the key is absent.
env_value() {
	local key="$1" line value=""
	while IFS= read -r line || [ -n "$line" ]; do
		line="${line#export }"
		case "$line" in
			"$key="*)
				value="${line#"$key="}"
				value="${value%$'\r'}"
				if [[ "$value" == \"*\" || "$value" == \'*\' ]]; then
					value="${value:1:${#value}-2}"
				fi
				;;
		esac
	done <"$ENV_FILE"
	printf '%s' "$value"
}

API_TOKEN="$(env_value CLOUDKIT_API_TOKEN)"
CONTAINER_ID="$(env_value CLOUDKIT_CONTAINER_ID)"
[ -n "$CONTAINER_ID" ] || CONTAINER_ID="$(env_value CLOUDKIT_CONTAINER_IDENTIFIER)"
SHAREE_EMAIL="${SHAREE_EMAIL_ARG:-$(env_value CLOUDKIT_SHAREE_EMAIL)}"

[ -n "$API_TOKEN" ] || die "CLOUDKIT_API_TOKEN is not set in $ENV_FILE"
if [ "$SINGLE" = false ] && [ -z "$SHAREE_EMAIL" ]; then
	die "sharee email required: set CLOUDKIT_SHAREE_EMAIL in $ENV_FILE or pass --sharee-email (or use --single)"
fi

if [ "$SINGLE" = true ]; then
	SECRET_NAMES=(CLOUDKIT_WEB_AUTH_TOKEN)
else
	SECRET_NAMES=(CLOUDKIT_WEB_AUTH_TOKEN CLOUDKIT_SHAREE_WEB_AUTH_TOKEN CLOUDKIT_SHAREE_EMAIL)
fi

current_branch() {
	git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD
}

rerun_failed() {
	local branch run_id
	branch="$(current_branch)"
	run_id="$(gh run list -R "$REPO" --workflow "$WORKFLOW" --branch "$branch" \
		--status failure -L1 --json databaseId --jq '.[0].databaseId // empty')"
	if [ -z "$run_id" ]; then
		info "no failed $WORKFLOW run found on $branch; nothing to re-run"
		return 0
	fi
	if [ "$DRY_RUN" = true ]; then
		echo "[dry-run] would re-run failed jobs of $WORKFLOW run $run_id ($branch)"
		return 0
	fi
	gh run rerun "$run_id" -R "$REPO" --failed
	echo "✅ Re-running failed jobs of run $run_id ($branch)"
}

if [ "$DRY_RUN" = true ]; then
	echo "[dry-run] would capture tokens with: mistdemo $([ "$SINGLE" = true ] && echo auth-token || echo auth-tokens) --output env"
	for name in "${SECRET_NAMES[@]}"; do
		echo "[dry-run] would set secret $name on $REPO"
	done
	if [ "$UPDATE_ENV" = true ]; then
		echo "[dry-run] would update ${SECRET_NAMES[*]} in $ENV_FILE"
	fi
	if [ "$RERUN" = true ]; then
		rerun_failed
	fi
	exit 0
fi

command -v gh >/dev/null 2>&1 || die "gh (GitHub CLI) is required"

# Build mistdemo unless a binary was supplied.
if [ -n "${MISTDEMO_BIN:-}" ]; then
	MISTDEMO="$MISTDEMO_BIN"
else
	info "Building mistdemo…"
	(cd "$MISTDEMO_DIR" && swift build --product mistdemo >&2)
	MISTDEMO="$(cd "$MISTDEMO_DIR" && swift build --show-bin-path)/mistdemo"
fi
[ -x "$MISTDEMO" ] || die "mistdemo binary not found at $MISTDEMO"

TMP_DIR="$(mktemp -d)"
chmod 700 "$TMP_DIR"
trap 'rm -rf "$TMP_DIR"' EXIT
CAPTURE="$TMP_DIR/capture.env"

# Credentials go through the environment, never argv. Prompts and progress
# are on stderr (the terminal); stdout carries only KEY=value lines.
if [ "$SINGLE" = true ]; then
	CMD=(auth-token)
else
	CMD=(auth-tokens)
fi
info "Starting browser sign-in ($ENVIRONMENT)…"
(
	export CLOUDKIT_API_TOKEN="$API_TOKEN"
	if [ -n "$CONTAINER_ID" ]; then
		export CLOUDKIT_CONTAINER_ID="$CONTAINER_ID"
	fi
	if [ -n "$SHAREE_EMAIL" ]; then
		export CLOUDKIT_SHAREE_EMAIL="$SHAREE_EMAIL"
	fi
	export CLOUDKIT_ENVIRONMENT="$ENVIRONMENT"
	"$MISTDEMO" "${CMD[@]}" --output env
) >"$CAPTURE"

# Parse captured KEY=value lines into VALUES[] (indexed like SECRET_NAMES).
VALUES=()
for name in "${SECRET_NAMES[@]}"; do
	value=""
	while IFS= read -r line || [ -n "$line" ]; do
		case "$line" in
			"$name="*) value="${line#"$name="}" ;;
		esac
	done <"$CAPTURE"
	if [ -z "$value" ] && [ "$name" = CLOUDKIT_SHAREE_EMAIL ]; then
		value="$SHAREE_EMAIL"
	fi
	[ -n "$value" ] || die "mistdemo did not output $name"
	VALUES+=("$value")
done

for i in "${!SECRET_NAMES[@]}"; do
	printf '%s' "${VALUES[$i]}" | gh secret set "${SECRET_NAMES[$i]}" -R "$REPO"
	echo "✅ Set secret ${SECRET_NAMES[$i]}"
done

if [ "$UPDATE_ENV" = true ]; then
	NEW_ENV="$TMP_DIR/updated.env"
	: >"$NEW_ENV"
	declare -a WRITTEN=()
	while IFS= read -r line || [ -n "$line" ]; do
		replaced=false
		for i in "${!SECRET_NAMES[@]}"; do
			name="${SECRET_NAMES[$i]}"
			case "${line#export }" in
				"$name="*)
					printf '%s=%s\n' "$name" "${VALUES[$i]}" >>"$NEW_ENV"
					WRITTEN[i]=1
					replaced=true
					break
					;;
			esac
		done
		[ "$replaced" = true ] || printf '%s\n' "$line" >>"$NEW_ENV"
	done <"$ENV_FILE"
	for i in "${!SECRET_NAMES[@]}"; do
		if [ -z "${WRITTEN[i]:-}" ]; then
			printf '%s=%s\n' "${SECRET_NAMES[$i]}" "${VALUES[$i]}" >>"$NEW_ENV"
		fi
	done
	# Rewrite in place so the file keeps its permissions/inode.
	cat "$NEW_ENV" >"$ENV_FILE"
	echo "✅ Updated ${SECRET_NAMES[*]} in $ENV_FILE"
fi

if [ "$RERUN" = true ]; then
	rerun_failed
fi
