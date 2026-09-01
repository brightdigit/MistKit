---
name: release
description: Run the MistKit release runbook — verify the vX.Y.Z release branch is green, assemble the ReleaseNotes.md section and README roadmap entry, merge to main, tag as X.Y.Z, publish the GitHub pre-release, and roll the Examples' MISTKIT_BRANCH pins. Use when asked to cut, prepare, or ship a release.
argument-hint: "Which release? e.g. v1.0.0-beta.5"
disable-model-invocation: true
---

# MistKit Release Runbook

## The naming rule

```
release branch  v1.0.0-beta.5   ← with v
release tag      1.0.0-beta.5   ← without v
```

This asymmetry is deliberate. `setup-mistkit` resolves `MISTKIT_BRANCH` with
`git ls-remote`, which matches **tags as well as branches**, so pinning the wrong
kind of ref succeeds silently and greens example CI without ever compiling the
code under release. The pin requirement therefore *inverts* at release time:

| Phase | `MISTKIT_BRANCH` must be |
|---|---|
| Before the release merge | the **branch** `v1.0.0-beta.5` |
| After publishing | the **tag** `1.0.0-beta.5` |

`Scripts/release.sh pins --expect-branch` / `--expect-tag` asserts the ref *kind*,
which is the check `setup-mistkit` itself cannot make.

## Stop conditions

Abort and ask the user if:

- `preflight` fails for any reason other than notes-not-yet-written.
- The milestone still has open issues (it warns; confirm the release is intended).
- The named branch is not the branch you are on.
- `main` has commits the release branch lacks.
- Any `git subrepo push` would be needed but the Example subrepos have local changes.

## Phases

Run everything from the release branch's own worktree
(`git trees add v1.0.0-beta.5 main` if it does not exist — never raw `git worktree`).

### 1. Preflight

```bash
./Scripts/release.sh preflight v1.0.0-beta.5
```

Checks branch shape, clean tree, tag availability, gating CI (`MistKit`,
`MistDemo`, `Examples` — *not* `Claude Code Review`, which is advisory), pins,
open milestone issues, then local `swift build`/`swift test`/`Scripts/lint.sh`.
Use `--skip-local` only when re-running after a green local pass.

### 2. Fix the pre-release pins

Must happen **before** the merge, so example CI actually tests this branch.

```bash
./Scripts/release.sh pins --roll-to v1.0.0-beta.5
git add Examples/*/.github/workflows/*.yml
git commit -m "ci(examples): pin MISTKIT_BRANCH to v1.0.0-beta.5"
git subrepo push Examples/BushelCloud
git subrepo push Examples/CelestraCloud
git push
```

Then confirm from a build log that `Setup MistKit` printed
`Pinning MistKit to v1.0.0-beta.5 @ <sha>` with a sha matching the branch tip,
and re-run `./Scripts/release.sh pins --expect-branch v1.0.0-beta.5`.

### 3. Assemble the notes

Release notes are a **flat bullet list** — no `###` category subsections.

```bash
./Scripts/release.sh notes-draft v1.0.0-beta.5
```

This writes the `## 1.0.0-beta.5` section to the top of `ReleaseNotes.md` and
prints README roadmap candidates. Then, by hand:

- Edit bullet wording and add issue refs: `* <desc> (#41, #42) by @user in <PR url>`.
- Add a `### v1.0.0-beta.5` section to the README Roadmap, above `### Backlog / Post-beta`.
- Bump the README `from:` snippet to the **currently released** tag (the new one does not exist yet).

```bash
./Scripts/release.sh check v1.0.0-beta.5   # must pass before proceeding
swift build && swift test && ./Scripts/lint.sh
git commit -am "docs: 1.0.0-beta.5 release notes and roadmap" && git push
```

### 4. Archive before merging

Load-bearing under squash: once the branch is deleted, squashed commits are
unreachable. Do this even if you plan a merge commit.

```bash
git tag "backup/v1.0.0-beta.5-pre-merge" v1.0.0-beta.5
git push origin "backup/v1.0.0-beta.5-pre-merge"
```

### 5. Release PR — ask before merging

```bash
gh pr create --base main --head v1.0.0-beta.5 --title "v1.0.0 beta.5" \
  --body-file <(./Scripts/release.sh publish 1.0.0-beta.5 --dry-run 2>/dev/null)
```

**Ask the user which merge shape to use.** Release branches are the documented
merge-commit case (`gh pr merge --merge`) — unlike feature PRs, which are always
rebase (1 commit) or squash (2+). Squash keeps `main` linear but makes the
archive tag from phase 4 the *only* preservation mechanism.

### 6. Tag — only after notes have landed

```bash
git checkout main && git pull --ff-only
./Scripts/release.sh verify-tag 1.0.0-beta.5 --at HEAD   # must pass first
git tag 1.0.0-beta.5          # lightweight, no -a, no v
git push origin 1.0.0-beta.5
```

`verify-tag --at HEAD` reads `ReleaseNotes.md` in the tree about to be tagged.
This is the guardrail for beta.3 and beta.4, both of which were tagged without
their own notes section. The `Release Check` workflow re-asserts it after the push.

### 7. Publish

```bash
./Scripts/release.sh publish 1.0.0-beta.5
```

Builds the body from `ReleaseNotes.md`, swapping `## 1.0.0-beta.5` for
`## What's Changed`. Add the intro blurb by hand afterwards if wanted.

### 8. Roll the pins to the tag

```bash
./Scripts/release.sh pins --roll-to 1.0.0-beta.5
./Scripts/release.sh pins --expect-tag 1.0.0-beta.5
git commit -am "ci(examples): pin MISTKIT_BRANCH to released 1.0.0-beta.5"
git subrepo push Examples/BushelCloud
git subrepo push Examples/CelestraCloud
git push
```

### 9. Clean up and open the next release

```bash
git push origin --delete v1.0.0-beta.5   # archive tag from phase 4 preserves it
git trees rm v1.0.0-beta.5 --apply
git trees add v1.0.0-beta.6 main
```

## This runbook will not

- Push the Example subrepos for you — it prints the `git subrepo push` commands.
- Delete a release branch before its archive tag exists.
- Tag before `check` / `verify-tag` passes.
- Choose the merge shape without asking.
