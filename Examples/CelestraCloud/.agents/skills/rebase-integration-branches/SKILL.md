---
name: rebase-integration-branches
description: >-
  Rebase mistkit and subrepo integration branches onto a release branch in
  this git-trees repo. Squashes each branch to one commit ahead of the release
  branch with CI-only integration changes. Use when rebasing integration
  branches, squashing mistkit/subrepo onto v1.0.0-dev.1, or syncing
  path-dependency CI for MistKit/CelestraKit.
disable-model-invocation: true
---

# Rebase Integration Branches (git-trees)

Squash `mistkit` and `subrepo` so each is **exactly one commit ahead** of the
release branch. Integration commits change **CI/workflow files only** unless
the user explicitly asks to change `Package.swift` / `Package.resolved`.

## Prerequisites

- Read `AGENTS.md` at the container root (sibling of worktree directories).
- Run git commands from the **container root** (parent of this worktree),
  not from inside a worktree, unless editing files.
- Confirm `RELEASE_BRANCH` with the user if unsure.

## Project config

Read [projects.md](projects.md). Defaults for this repo:

| Key | Value |
|-----|-------|
| `RELEASE_BRANCH` | `v1.0.0-dev.1` |
| `MAIN_BRANCH` | `main` |
| `MISTKIT_REF` | `1.0.0-beta.4` |
| `KIT_PACKAGE` | `CelestraKit` |
| `KIT_PATH` | `../CelestraKit` |
| Primary workflow | `.github/workflows/CelestraCloud.yml` |
| Feed update workflow | `.github/workflows/update-feeds.yml` |
| MistKit path (if used) | `../..` |

## Target end state

```
main
 └── RELEASE_BRANCH (+N commits ahead of main, often 1)
      └── mistkit  (+1 integration commit, CI only by default)
      └── subrepo  (+1 integration commit, CI only by default)
```

Verify after push:

```bash
git rev-list --count origin/$MAIN_BRANCH..origin/mistkit   # expect: N+1
git rev-list --count $RELEASE_BRANCH..origin/mistkit         # expect: 1
git rev-list --count origin/mistkit..origin/$MAIN_BRANCH     # expect: 0
```

## Workflow checklist

```
- [ ] Step 0: Pre-flight — inspect branch divergence
- [ ] Step 1: Backup current branch tips
- [ ] Step 2: Rebase mistkit (squash onto RELEASE_BRANCH)
- [ ] Step 3: Push mistkit
- [ ] Step 4: Rebase subrepo (squash onto RELEASE_BRANCH)
- [ ] Step 5: Push subrepo
- [ ] Step 6: Cleanup worktrees, restore local branch refs
- [ ] Step 7: Report commit counts and diff stats
```

---

## Step 0: Pre-flight

```bash
cd <container-root>   # e.g. .../CelestraCloud
git fetch origin

git rev-list --count $RELEASE_BRANCH..mistkit
git rev-list --count mistkit..$RELEASE_BRANCH
git rev-list --count origin/$MAIN_BRANCH..mistkit
git diff --stat $RELEASE_BRANCH mistkit
git diff --stat $RELEASE_BRANCH subrepo
```

**Stop and ask** if force-push was not requested, backups don't exist, or the
user wants to preserve full branch history.

---

## Step 1: Backup branches

```bash
git branch -f backup/mistkit-pre-squash mistkit
git branch -f backup/subrepo-pre-squash subrepo
git push -u origin backup/mistkit-pre-squash backup/subrepo-pre-squash
```

Existing backups `mistkit-backup` / `subrepo-backup` may also be present — update
or create `backup/*-pre-squash` for consistency with BushelCloud.

---

## Step 2: Squash mistkit onto release branch

```bash
git trees add mistkit --no-push
cd mistkit
git reset --hard $RELEASE_BRANCH
```

### mistkit — CI changes

1. **Delete** `.github/workflows/dependency-policy.yml`.

2. **Primary workflow** (`.github/workflows/CelestraCloud.yml`) — release branch
   may already have `setup-mistkit`. Add only where missing:
   - `env`: `MISTKIT_BRANCH: 1.0.0-beta.4` (match existing tag format in repo)
   - After checkout in each build job (`build-ubuntu`, `build-macos`,
     `build-macos-platforms`):

   ```yaml
   - name: Setup MistKit
     uses: brightdigit/MistKit/.github/actions/setup-mistkit@main
     with:
       branch: ${{ env.MISTKIT_BRANCH }}
   ```

3. **Feed update workflow** (`.github/workflows/update-feeds.yml`) — add
   setup-mistkit after checkout in the `build` job if missing (needed when
   Package.swift uses a local MistKit path).

4. **Do not carry over** stale drift: source changes, Swift version
   downgrades, etc.

### mistkit — Package changes (only if user requests)

```swift
.package(name: "MistKit", path: "../.."),
```

Remove the `mistkit` pin from `Package.resolved`.

### Commit and push mistkit

```bash
git add -A && git diff --stat $RELEASE_BRANCH
git commit -m "$(cat <<'EOF'
chore: wire setup-mistkit CI for mistkit integration branch

Add setup-mistkit to build workflows (pinned to 1.0.0-beta.4) and remove
dependency-policy workflow since integration branches use local path deps.
EOF
)"
git log --oneline $RELEASE_BRANCH..HEAD   # exactly 1 commit
git push --force-with-lease -u origin HEAD
cd .. && git trees rm mistkit --apply
```

---

## Step 4: Squash subrepo onto release branch

```bash
git trees add subrepo --no-push
cd subrepo
git reset --hard $RELEASE_BRANCH
```

### subrepo — CI changes

1. **Delete** `.github/workflows/dependency-policy.yml`.

2. After checkout in each build job of `CelestraCloud.yml`, add sed override
   before setup-mistkit / swift-build:

   Ubuntu:
   ```yaml
   - name: Update Package.swift to use remote CelestraKit branch
     run: |
       sed -i 's|\.package(path: "\.\./CelestraKit")|.package(url: "https://github.com/brightdigit/CelestraKit.git", branch: "subrepo")|g' Package.swift
       rm -f Package.resolved
   ```

   macOS:
   ```yaml
   - name: Update Package.swift to use remote CelestraKit branch
     run: |
       sed -i '' 's|\.package(path: "\.\./CelestraKit")|.package(url: "https://github.com/brightdigit/CelestraKit.git", branch: "subrepo")|g' Package.swift
       rm -f Package.resolved
   ```

### subrepo — Package changes (only if user requests)

```swift
.package(path: "../CelestraKit"),
```

Remove the `celestrakit` pin from `Package.resolved`.

### Commit and push subrepo

```bash
git add -A && git diff --stat $RELEASE_BRANCH
git commit -m "$(cat <<'EOF'
chore: wire subrepo CI branch override for CelestraKit integration branch

Add CI sed steps to substitute the subrepo branch during builds. Remove
dependency-policy workflow since integration branches use local path deps.
EOF
)"
git push --force-with-lease -u origin HEAD
cd .. && git trees rm subrepo --apply
```

---

## Step 6: Cleanup

```bash
git branch -f mistkit origin/mistkit
git branch -f subrepo origin/subrepo
```

---

## Optional: revert Package files only

```bash
git trees add <branch> --no-push
cd <branch>
git checkout $RELEASE_BRANCH -- Package.swift Package.resolved
git commit -m "revert: restore Package.swift and Package.resolved from $RELEASE_BRANCH"
git push origin <branch>
cd .. && git trees rm <branch> --apply && git branch -f <branch> origin/<branch>
```

Warn: subrepo sed steps require `.package(path: "../CelestraKit")` in Package.swift.

---

## Rules

1. Never modify `CelestraCloud.git/` directly.
2. Never touch the release-branch worktree while rebasing integration branches.
3. Use `git trees add --no-push`.
4. Always `--force-with-lease`.
5. Ask before force-push if not confirmed in this session.

## Related

BushelCloud carries the same skill pattern with `BushelKit` and `BushelCloud.yml`.
See `brightdigit/BushelCloud` `.agents/skills/rebase-integration-branches/`.
