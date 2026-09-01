# Agent Notes

Standing always/never directives and corrections from the human. Agents must read this file at the start of every session before doing work.

## How to maintain

- Append one line per directive **proactively** (without being asked) whenever the human makes a correction or gives an always/never instruction.
- Newest lines at the bottom.
- One line per entry.
- When a directive supersedes an earlier one, update or remove the stale line rather than leaving both.

## Directives

- ALWAYS read `.claude/agent-notes.md` and `.claude/memory/MEMORY.md` at the start of every session before doing work.
- ALWAYS append corrections and always/never directives to `.claude/agent-notes.md` proactively; ALWAYS write project-scoped facts to `.claude/memory/` (with an index line in `MEMORY.md`).
- NEVER store project-scoped memories in a native or global memory system (Claude Code `~/.claude/projects/*/memory/`, Cursor memories, etc.) — use `.claude/memory/` in this repo instead.
- NEVER run bare `git stash`/`git stash pop`/`git stash drop` in this repo — the stash stack is shared across ALL worktrees, so a pop in one worktree can bury or restore another branch's WIP; commit to your own branch instead.
- CI: in-development Swift branches (e.g. 6.4 snapshots) belong IN the `build-ubuntu` matrix as a swift entry carrying an `image` override (ConfigKeyKit pattern: `{"version":"6.4","image":"swiftlang/swift:nightly-6.4.x"}` plus a `container:` fallback expression) — NEVER as a separate job. Supersedes the earlier "no nightly toolchains" directive.
- Repo-wide CI version bumps (Xcode/simulator/toolchain) DO extend into the `Examples/` subrepos — update BushelCloud and CelestraCloud in the same pass rather than deferring them to their own repos.
- Follow sibling brightdigit repos (e.g. ConfigKeyKit) for current CI workflow shape before inventing a new one.
- Feature-branch PRs: NEVER merge-commit. ALWAYS rebase if the PR has exactly 1 commit (`gh pr merge --rebase`); ALWAYS squash if it has 2+ commits (`gh pr merge --squash`). Count commits before merging.
- Release PRs (a `v*` release branch into `main`) are the one merge-commit case — the "never merge-commit" rule above covers FEATURE PRs only; still confirm the shape with the human before merging.
- NEVER tag a release before its `ReleaseNotes.md` section exists in the tree being tagged — run `./Scripts/release.sh verify-tag <tag> --at HEAD` first (beta.3 and beta.4 both shipped tags with no notes).
- Release notes are a FLAT bullet list for **new** entries — do not add `###` category subsections; preserve the existing beta.1–beta.4 sections.
- NEVER delete a released beta branch — after publication, create the next beta branch from `main` with `git trees add`.
- ALWAYS manage worktrees with `git trees` (`add`/`rm`/`list`/`clean`), never raw `git worktree`.
- MistKitConfiguration#1 is merged and `1.0.0-beta.1` is tagged (ConfigKeyKit `1.0.0-beta.3`). The published `main` manifest must stay tag-only — `dependency-policy.yml` enforces this on non-draft PRs to `main`. Branch pins live on the `mistkit-beta.5` integration branch, which must NEVER be merged to `main` or tagged.
- MistDemo's own `resolveBool` may now be replaced by ConfigKeyKit `read(_:)`: the boolean fix (ConfigKeyKit#8) shipped in `1.0.0-beta.3` (2026-08-31). Verify behaviour before swapping; this supersedes the earlier "keep resolveBool until tagged" directive.
- `git subrepo push Packages/MistKitConfiguration` refuses ("new changes upstream") and would clobber the standalone `url:` MistKit line with the monorepo `path:` overlay; push subrepo-only changes by applying them to a clone of the standalone repo instead, then record the pushed SHA in `.gitrepo`'s `commit =`.
- NEVER switch `Examples/*/Package.swift` to a tagged `from:` just because a monorepo package was released — the Examples dogfood UNRELEASED MistKit and must keep `path:` for every in-monorepo package, with CI rewriting them to branch-HEAD `revision:` pins via `setup-mistkitconfiguration` (takes both `mistkit-branch` and `mistkitconfiguration-branch`). A published tag is for downstream consumers, not for the Examples.
- `Packages/MistKitConfiguration` is scaffolding for the `v1.0.0-beta.5` release line ONLY. Feature PRs merge into `v1.0.0-beta.5` with the subrepo intact; the release PR `v1.0.0-beta.5` → `main` MUST delete it (and its `examples.yml` lane) so no MistKit release ships a package tracking that same unreleased release.
- MistKitConfiguration test gaps belong in `Packages/MistKitConfiguration/` (subrepo) or the standalone `brightdigit/MistKitConfiguration` repo — NEVER add MKC unit tests to the monorepo root `Tests/` or chase MKC patch coverage in MistKit's codecov upload; `codecov.yml` already ignores that path.
- Lint findings for agents: use `LINT_REPORT=1 ./Scripts/lint.sh` (human summary on stderr + JSON between `### MISTKIT_LINT_REPORT_* ###` markers on stdout) or `LINT_REPORT=json ./Scripts/lint.sh` (JSON only on stdout). Report mode is read-only and walks swift-format, SwiftLint, `swift build`, and Periphery; all four lint tools run with `--strict` so any warning or error fails the pipeline; success requires exit 0 and `summary.totalFindings == 0`. See `.claude/skills/fix-lint/SKILL.md`.
- Prefer force unwraps (`!`) over verbose `guard let … else { preconditionFailure }` for compile-time-known-safe values (constant URL literals, test fixtures); suppress lint with `swift-format-ignore: NeverForceUnwrap` plus a `swiftlint:disable force_unwrapping` / `swiftlint:enable force_unwrapping` block when a doc comment sits between the disable and the unwrap (`:next` only when the unwrap is the immediate next line).
- NEVER use `Task.sleep(for:)` / `Duration` clocks in MistKitTests — package deployment target is iOS 14 (and peers); use `Task.sleep(nanoseconds:)` instead (CI iOS simulator build failed on CourierTests for this).
- Before writing any synthesis/analysis document, READ the existing reports in `.claude/memory/_raw/` first — they are the prior art and the new work must cross-reference (corroborate/sharpen/contradict) them rather than restate or duplicate them.
