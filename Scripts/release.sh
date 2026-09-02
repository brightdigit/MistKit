#!/bin/bash

# MistKit release tooling.
#
# Naming convention (deliberate, asserted throughout):
#   release branch = v<version>   e.g. v1.0.0-beta.5
#   release tag    =  <version>   e.g.  1.0.0-beta.5
# The `v` is stripped in exactly one place — tag_for() — so the rest of the
# system never re-derives it.
#
# Most subcommands are read-only checks that accumulate into ERRORS and exit
# non-zero, following Scripts/lint.sh rather than blanket `set -e`.

REPO="brightdigit/MistKit"
REPO_URL="https://github.com/${REPO}.git"

# Workflows that gate a release. Explicitly listed rather than "all green":
# Claude Code Review is advisory and is routinely red, so an all-green rule
# would make preflight unpassable and get bypassed. No env-var override —
# a release gate is policy, not configuration.
REQUIRED_WORKFLOWS=("MistKit" "MistDemo Integration" "Examples")

# Example workflows carrying a MISTKIT_BRANCH pin. Both are git subrepos.
# When Packages/MistKitConfiguration lands (#407), add its workflow here and
# to the git subrepo push hints in cmd_pins.
PIN_FILES=(
	"Examples/BushelCloud/.github/workflows/BushelCloud.yml"
	"Examples/CelestraCloud/.github/workflows/CelestraCloud.yml"
)

ERRORS=0
DRY_RUN=false
QUIET_TRAILER=false

pass() { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
fail() { echo "❌ $*"; ERRORS=$((ERRORS + 1)); }
info() { echo "→  $*"; }

die() {
	echo "❌ $*" >&2
	exit 1
}

# Run a mutating command, or print it under --dry-run.
run() {
	if [ "$DRY_RUN" = true ]; then
		echo "   [dry-run] $*"
	else
		"$@" || fail "command failed: $*"
	fi
}

repo_root() {
	git rev-parse --show-toplevel 2>/dev/null
}

# The single place `v` is stripped.
tag_for() {
	echo "${1#v}"
}

branch_for() {
	echo "v${1#v}"
}

current_branch() {
	git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Newest release already recorded in ReleaseNotes.md, e.g. 1.0.0-beta.4.
previous_tag() {
	sed -n 's/^## \(.*\)$/\1/p' ReleaseNotes.md | head -1
}

# The release immediately before $1 — skips $1 when notes-draft prepended it.
prior_released_tag() {
	local excluding="$1"
	sed -n 's/^## \(.*\)$/\1/p' ReleaseNotes.md \
		| awk -v skip="$excluding" '$0 != skip { print; exit }'
}

validate_release_tag() {
	local tag="$1"
	if [[ "$tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?$ ]]; then
		return 0
	fi
	die "tag '$tag' does not match the release pattern (expected e.g. 1.0.0-beta.5)"
}

# Print the ReleaseNotes.md section for a tag (heading included).
notes_section() {
	awk -v tag="## $1" '
		$0 == tag { found = 1; print; next }
		found && /^## / { exit }
		found { print }
	' ReleaseNotes.md
}

# Same, but from a given git tree-ish rather than the working tree.
notes_section_at() {
	git show "$1:ReleaseNotes.md" 2>/dev/null | awk -v tag="## $2" '
		$0 == tag { found = 1; print; next }
		found && /^## / { exit }
		found { print }
	'
}

usage() {
	cat <<'EOF'
usage: ./Scripts/release.sh <command> [args]

  preflight   [branch]          read-only gate: worktree, CI, build/test/lint
  notes-draft [branch]          write the ReleaseNotes.md section (--stdout to preview)
  check       [branch]          validate the prepared tree before the release PR
  pins        [--expect-branch <ref> | --expect-tag <ref> | --roll-to <ref>]
  publish     <tag>             create the GitHub pre-release from ReleaseNotes.md
  verify-tag  <tag> [--at <sha>]  assert a tag (or a candidate commit) is releasable

Common flags: --dry-run, --skip-local (preflight), --stdout (notes-draft)

Branch defaults to the current branch. Tags are derived by stripping `v`.
EOF
}

# ---------------------------------------------------------------- preflight

cmd_preflight() {
	local branch="${1:-$(current_branch)}"
	local skip_local="$2"
	local tag
	tag=$(tag_for "$branch")

	echo "🔍 Preflight for $branch (tag: $tag)"
	echo

	# Branch shape. The `v` prefix is the convention, so assert it rather than
	# silently accepting a tag-shaped value.
	if [[ "$branch" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?$ ]]; then
		pass "branch name '$branch' matches the release pattern"
	else
		fail "branch '$branch' is not a release branch (expected v<semver>, e.g. v1.0.0-beta.5)"
	fi

	# Right worktree. Never suggest `git stash` — the stack is shared across
	# every worktree in this layout.
	if [ "$(current_branch)" = "$branch" ]; then
		pass "running in the '$branch' worktree"
	else
		fail "current branch is '$(current_branch)', not '$branch'"
		info "worktrees:"
		git worktree list | sed 's/^/     /'
	fi

	if [ -z "$(git status --porcelain)" ]; then
		pass "working tree is clean"
	else
		fail "working tree is dirty (commit first — do NOT git stash in this repo)"
	fi

	# The tag must not exist yet, locally or on the remote.
	if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
		fail "tag '$tag' already exists locally"
	elif [ -n "$(git ls-remote --tags origin "$tag" 2>/dev/null)" ]; then
		fail "tag '$tag' already exists on origin"
	else
		pass "tag '$tag' does not exist yet"
	fi

	# Notes for this release must NOT be written yet at preflight time; they
	# are authored in the notes phase. Warn rather than fail if already there.
	if [ -n "$(notes_section "$tag")" ]; then
		warn "ReleaseNotes.md already has a '## $tag' section (re-running preflight?)"
	else
		info "ReleaseNotes.md has no '## $tag' section yet — author it in the notes phase"
	fi

	# CI on the branch tip, limited to the gating workflows.
	local sha
	sha=$(git rev-parse HEAD)
	if command -v gh >/dev/null 2>&1; then
		local runs
		runs=$(gh run list --branch "$branch" --commit "$sha" \
			--json workflowName,conclusion,status 2>/dev/null)
		if [ -z "$runs" ] || [ "$runs" = "[]" ]; then
			fail "no CI runs found for $branch @ ${sha:0:7}"
		else
			local wf conclusion
			for wf in "${REQUIRED_WORKFLOWS[@]}"; do
				conclusion=$(echo "$runs" | jq -r --arg w "$wf" \
					'[.[] | select(.workflowName == $w)] | first | .conclusion // "missing"')
				case "$conclusion" in
					success) pass "CI '$wf' is green" ;;
					missing) fail "CI '$wf' has no run for this commit" ;;
					*)       fail "CI '$wf' is '$conclusion'" ;;
				esac
			done
		fi
	else
		fail "gh CLI not found; cannot verify CI"
	fi

	# Pins must point at THIS branch before the release merge, so example CI
	# actually compiles the code being released.
	check_pins --expect-branch "$branch"

	# Open milestone issues are a warning, not a gate.
	if command -v gh >/dev/null 2>&1; then
		local open
		open=$(gh issue list --milestone "$branch" --state open \
			--json number,title 2>/dev/null)
		if [ -n "$open" ] && [ "$open" != "[]" ]; then
			warn "milestone '$branch' still has open issues:"
			echo "$open" | jq -r '.[] | "     #\(.number) \(.title)"'
		else
			pass "no open issues in milestone '$branch'"
		fi
	fi

	# Local build/test/lint. Default is to run them.
	if [ "$skip_local" = "--skip-local" ]; then
		warn "skipping local build/test/lint (--skip-local)"
	else
		info "running swift build"
		swift build >/dev/null 2>&1 && pass "swift build" || fail "swift build"
		info "running swift test"
		swift test >/dev/null 2>&1 && pass "swift test" || fail "swift test"
		info "running Scripts/lint.sh"
		./Scripts/lint.sh >/dev/null 2>&1 && pass "lint" || fail "lint"
	fi
}

# --------------------------------------------------------------------- pins

pin_value() {
	sed -n 's/^[[:space:]]*MISTKIT_BRANCH:[[:space:]]*\(.*\)$/\1/p' "$1" | head -1
}

# Assert each pin is the expected ref AND resolves as the right KIND of ref.
# setup-mistkit resolves MISTKIT_BRANCH with `git ls-remote`, which matches
# tags as well as branches — so a tag pins silently and greens example CI
# without ever compiling the branch. That is the check gh cannot do for us.
check_pins() {
	local mode="$1" expected="$2"
	local file value

	for file in "${PIN_FILES[@]}"; do
		[ -f "$file" ] || { fail "missing $file"; continue; }
		value=$(pin_value "$file")
		local name="${file#Examples/}"
		name="${name%%/*}"

		if [ -z "$value" ]; then
			fail "$name: no MISTKIT_BRANCH found"
			continue
		fi

		if [ "$value" != "$expected" ]; then
			fail "$name: MISTKIT_BRANCH is '$value', expected '$expected'"
			continue
		fi

		case "$mode" in
			--expect-branch)
				if [ -n "$(git ls-remote --heads "$REPO_URL" "$value" 2>/dev/null)" ]; then
					pass "$name: pinned to branch '$value'"
				else
					fail "$name: '$value' does not resolve as a BRANCH (a tag here would green CI without testing the branch)"
				fi
				;;
			--expect-tag)
				if [ -n "$(git ls-remote --tags "$REPO_URL" "$value" 2>/dev/null)" ]; then
					pass "$name: pinned to tag '$value'"
				else
					fail "$name: '$value' does not resolve as a TAG"
				fi
				;;
		esac
	done
}

cmd_pins() {
	local mode="$1" ref="$2"

	case "$mode" in
		--expect-branch|--expect-tag)
			[ -n "$ref" ] || die "$mode needs a ref"
			echo "🔍 Checking MISTKIT_BRANCH pins against '$ref'"
			check_pins "$mode" "$ref"
			;;
		--roll-to)
			[ -n "$ref" ] || die "--roll-to needs a ref"
			echo "🔄 Rolling MISTKIT_BRANCH pins to '$ref'"
			local file
			for file in "${PIN_FILES[@]}"; do
				[ -f "$file" ] || { fail "missing $file"; continue; }
				if [ "$DRY_RUN" = true ]; then
					echo "   [dry-run] $file: $(pin_value "$file") → $ref"
				else
					# BSD/GNU sed compatible: write to a temp file.
					sed "s|^\([[:space:]]*MISTKIT_BRANCH:[[:space:]]*\).*$|\1$ref|" \
						"$file" > "$file.tmp" && mv "$file.tmp" "$file"
					pass "$file → $ref"
				fi
			done
			echo
			# These files live in git subrepos; pushing them is a separate,
			# deliberate step the human runs.
			info "Examples are git subrepos — after committing, push each:"
			echo "     git subrepo push Examples/BushelCloud"
			echo "     git subrepo push Examples/CelestraCloud"
			;;
		*)
			# Report-only.
			echo "🔍 Current MISTKIT_BRANCH pins"
			local file
			for file in "${PIN_FILES[@]}"; do
				[ -f "$file" ] && echo "   $file: $(pin_value "$file")"
			done
			;;
	esac
}

# -------------------------------------------------------------- notes-draft

cmd_notes_draft() {
	local branch="${1:-$(current_branch)}"
	local to_stdout="$2"
	local tag prev
	tag=$(tag_for "$branch")
	prev=$(previous_tag)

	[ -n "$prev" ] || die "could not read the previous tag from ReleaseNotes.md"
	command -v gh >/dev/null 2>&1 || die "gh CLI is required"

	if [ -n "$(notes_section "$tag")" ]; then
		die "ReleaseNotes.md already has a '## $tag' section; edit it by hand"
	fi

	echo "📝 Drafting notes for $tag (since $prev)" >&2

	local body
	body=$(gh api "repos/${REPO}/releases/generate-notes" \
		-f tag_name="$tag" \
		-f target_commitish="$branch" \
		-f previous_tag_name="$prev" \
		--jq .body 2>/dev/null) || die "generate-notes failed"

	# Keep the flat bullet list only: drop GitHub's own headings and its
	# trailing compare line, then re-add ours in the house format.
	local section
	section=$(printf '## %s\n\n%s\n\n**Full Changelog**: https://github.com/%s/compare/%s...%s\n' \
		"$tag" \
		"$(echo "$body" | grep '^\* ' )" \
		"$REPO" "$prev" "$tag")

	if [ "$to_stdout" = "--stdout" ] || [ "$DRY_RUN" = true ]; then
		echo "$section"
		QUIET_TRAILER=true
	else
		printf '%s\n\n%s' "$section" "$(cat ReleaseNotes.md)" > ReleaseNotes.md.tmp \
			&& mv ReleaseNotes.md.tmp ReleaseNotes.md
		pass "wrote '## $tag' to the top of ReleaseNotes.md"
		info "edit the bullet wording and add issue refs, then run: check $branch"
	fi

	# Raw material for the README roadmap checklist.
	local closed
	closed=$(gh issue list --milestone "$branch" --state closed \
		--json number,title,url 2>/dev/null)
	if [ -n "$closed" ] && [ "$closed" != "[]" ]; then
		echo >&2
		echo "README roadmap candidates (closed in milestone $branch):" >&2
		echo "$closed" | jq -r '.[] | "- [x] [\(.title)](\(.url)) ✅"' >&2
	fi
}

# -------------------------------------------------------------------- check

cmd_check() {
	local branch="${1:-$(current_branch)}"
	local tag prev
	tag=$(tag_for "$branch")
	prev=$(prior_released_tag "$tag")

	echo "🔍 Checking the prepared tree for $tag"
	echo

	# The notes section must be present and be the newest one.
	local first
	first=$(sed -n 's/^## \(.*\)$/\1/p' ReleaseNotes.md | head -1)
	if [ "$first" = "$tag" ]; then
		pass "ReleaseNotes.md leads with '## $tag'"
	else
		fail "ReleaseNotes.md leads with '## $first', expected '## $tag'"
	fi

	local section
	section=$(notes_section "$tag")
	if [ -z "$section" ]; then
		fail "no '## $tag' section in ReleaseNotes.md"
	else
		local bullets
		bullets=$(echo "$section" | grep -c '^\* ')
		if [ "$bullets" -gt 0 ]; then
			pass "section has $bullets bullet(s)"
		else
			fail "section has no '* ' bullets"
		fi

		# Notes are a flat bullet list; subsections are no longer used.
		if echo "$section" | grep -q '^### '; then
			warn "section contains '###' subheadings; releases now use a flat bullet list"
		fi

		local expected_compare="**Full Changelog**: https://github.com/${REPO}/compare/"
		if echo "$section" | grep -qF "${expected_compare}"; then
			if echo "$section" | grep -qF "${expected_compare}...${tag}" \
				|| echo "$section" | grep -qE "compare/.+\.\.\.${tag//./\\.}$"; then
				pass "Full Changelog line targets $tag"
			else
				fail "Full Changelog line does not end at '...$tag'"
			fi
		else
			fail "section has no '**Full Changelog**' compare line"
		fi
	fi

	# README roadmap section for this release.
	if grep -q "^### $branch\$" README.md; then
		pass "README.md has a '### $branch' roadmap section"
	else
		fail "README.md has no '### $branch' roadmap section"
	fi

	# The SwiftPM snippet should name the currently-released tag; the new one
	# does not exist yet at check time.
	local snippet
	snippet=$(grep -o 'from: "[^"]*"' README.md | head -1 | sed 's/from: "//;s/"//')
	if [ -z "$snippet" ]; then
		warn "no 'from:' snippet found in README.md"
	elif [ -z "$prev" ]; then
		fail "could not determine the prior release tag from ReleaseNotes.md"
	elif [ "$snippet" = "$prev" ]; then
		pass "README 'from:' snippet names the currently released tag ($snippet)"
	elif [ "$snippet" = "$tag" ]; then
		fail "README 'from:' snippet is '$snippet' but the tag does not exist yet; expected '$prev'"
	else
		fail "README 'from:' snippet is '$snippet'; expected '$prev' (the currently released tag)"
	fi

	check_pins --expect-branch "$branch"
}

# ------------------------------------------------------------------ publish

cmd_publish() {
	local tag="$1"
	[ -n "$tag" ] || die "publish needs a tag"
	[ "$tag" = "${tag#v}" ] || die "tags carry no 'v' prefix; use '${tag#v}'"
	validate_release_tag "$tag"

	local section
	section=$(notes_section "$tag")
	[ -n "$section" ] || die "no '## $tag' section in ReleaseNotes.md"

	# The release body is the notes section with the version heading swapped
	# for GitHub's conventional one.
	local body
	body=$(echo "$section" | sed "1s|^## ${tag}$|## What's Changed|")

	local prerelease_flag=""
	if [[ "$tag" == *-* ]]; then
		prerelease_flag="--prerelease"
	else
		# A stable release is a policy call, not a default.
		read -r -p "Tag '$tag' looks stable. Publish as a full release (not a pre-release)? [y/N] " reply
		[[ "$reply" =~ ^[Yy]$ ]] || prerelease_flag="--prerelease"
	fi

	if [ "$DRY_RUN" = true ]; then
		echo "   [dry-run] gh release create $tag --title $tag $prerelease_flag --verify-tag --notes-file -" >&2
		echo "--- body ---" >&2
		echo "$body"
		QUIET_TRAILER=true
		return
	fi

	echo "$body" | gh release create "$tag" \
		--title "$tag" \
		$prerelease_flag \
		--verify-tag \
		--notes-file - \
		&& pass "published $tag" \
		|| fail "gh release create failed"
}

# --------------------------------------------------------------- verify-tag

# Assert a tag — or a candidate commit, via --at — is releasable. Reads the
# TAGGED TREE, which is what catches notes that landed after the tag.
cmd_verify_tag() {
	local tag="$1"
	local ref="${2:-$1}"

	[ -n "$tag" ] || die "verify-tag needs a tag"

	echo "🔍 Verifying $tag (at ${ref})"
	echo

	if [ "$tag" = "${tag#v}" ]; then
		pass "tag '$tag' has no 'v' prefix"
	else
		fail "tag '$tag' must not carry a 'v' prefix (branches do, tags do not)"
	fi

	if [[ "$tag" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-z]+\.[0-9]+)?$ ]]; then
		pass "tag '$tag' matches the release pattern"
	else
		fail "tag '$tag' does not match the release pattern (expected e.g. 1.0.0-beta.5)"
	fi

	git rev-parse -q --verify "$ref" >/dev/null 2>&1 || die "ref '$ref' not found"

	local head_line
	head_line=$(git show "$ref:ReleaseNotes.md" 2>/dev/null | head -1)
	if [ "$head_line" = "## $tag" ]; then
		pass "ReleaseNotes.md at $ref leads with '## $tag'"
	else
		fail "ReleaseNotes.md at $ref leads with '$head_line', expected '## $tag'"
	fi

	if [ -n "$(notes_section_at "$ref" "$tag")" ]; then
		pass "notes section for $tag is present in the tagged tree"
	else
		fail "no '## $tag' section in the tree at $ref"
	fi

	if git show "$ref:README.md" 2>/dev/null | grep -q "^### v${tag}\$"; then
		pass "README.md at $ref has the '### v$tag' roadmap section"
	else
		fail "README.md at $ref has no '### v$tag' roadmap section"
	fi

	# Resolve main however it is available: a tag-triggered CI checkout may
	# have no origin/main remote-tracking ref, so fetch it if needed.
	local main_ref=""
	if git rev-parse -q --verify origin/main >/dev/null 2>&1; then
		main_ref="origin/main"
	elif git rev-parse -q --verify refs/heads/main >/dev/null 2>&1; then
		main_ref="refs/heads/main"
	elif git fetch --quiet origin main 2>/dev/null && git rev-parse -q --verify FETCH_HEAD >/dev/null 2>&1; then
		main_ref="FETCH_HEAD"
	fi

	if [ -z "$main_ref" ]; then
		fail "could not resolve main to check tag ancestry"
	elif git merge-base --is-ancestor "$ref" "$main_ref" 2>/dev/null; then
		pass "$ref is an ancestor of main ($main_ref)"
	else
		fail "$ref is not an ancestor of main ($main_ref)"
	fi
}

# ----------------------------------------------------------------- dispatch

ROOT=$(repo_root) || die "not in a git worktree"
cd "$ROOT" || die "could not cd to $ROOT"

COMMAND="$1"
shift 2>/dev/null || true

ARGS=()
AT_REF=""
SKIP_LOCAL=false
STDOUT=false

while [ $# -gt 0 ]; do
	case "$1" in
		--dry-run) DRY_RUN=true ;;
		--skip-local)
			[ "$COMMAND" = preflight ] || die "--skip-local is only valid for preflight"
			SKIP_LOCAL=true
			;;
		--stdout)
			[ "$COMMAND" = notes-draft ] || die "--stdout is only valid for notes-draft"
			STDOUT=true
			;;
		--at)
			[ "$COMMAND" = verify-tag ] || die "--at is only valid for verify-tag"
			shift
			[ -n "${1:-}" ] || die "--at requires a ref"
			AT_REF="$1"
			;;
		*) ARGS+=("$1") ;;
	esac
	shift
done

case "$COMMAND" in
	preflight)
		if [ "$SKIP_LOCAL" = true ]; then
			cmd_preflight "${ARGS[0]}" "--skip-local"
		else
			cmd_preflight "${ARGS[0]}"
		fi
		;;
	notes-draft)
		if [ "$STDOUT" = true ]; then
			cmd_notes_draft "${ARGS[0]}" "--stdout"
		else
			cmd_notes_draft "${ARGS[0]}"
		fi
		;;
	check)       cmd_check "${ARGS[0]}" ;;
	pins)        cmd_pins "${ARGS[0]}" "${ARGS[1]}" ;;
	publish)     cmd_publish "${ARGS[0]}" ;;
	verify-tag)  cmd_verify_tag "${ARGS[0]}" "${AT_REF:-${ARGS[0]}}" ;;
	-h|--help|help|"") usage; exit 0 ;;
	*)           usage; die "unknown command: $COMMAND" ;;
esac

if [ "${QUIET_TRAILER:-false}" != true ]; then
	echo
	if [ $ERRORS -gt 0 ]; then
		echo "Completed with $ERRORS error(s)"
		exit 1
	fi
	echo "OK"
fi
[ $ERRORS -gt 0 ] && exit 1
exit 0
