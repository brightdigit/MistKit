---
name: project_release_process
description: MistKit release mechanics — v-prefixed branch vs bare tag, pins invert at release, notes must exist in the tagged tree, notes are a flat bullet list
metadata:
  type: project
---

The MistKit release process is encoded in `.claude/skills/release/SKILL.md` (invoke as
`/release`) with mechanical checks in `Scripts/release.sh`. The facts that are **not**
derivable from the code:

**Naming is asymmetric on purpose.** Release branch `v1.0.0-beta.5`; release tag
`1.0.0-beta.5` (lightweight, no `v`). All 26 release tags follow this.

**Pin semantics invert at release.** `setup-mistkit` resolves `MISTKIT_BRANCH` with
`git ls-remote`, which matches tags *and* branches, so the wrong kind of ref pins
silently and greens example CI without compiling the code under release. Before the
release merge the pin must be the **branch**; after publishing, the **tag**. Only
`./Scripts/release.sh pins --expect-branch|--expect-tag` asserts the ref *kind* — see
[[project_mistkit_branch_pin_resolves_tags]].

**A tag must contain its own notes.** Both `1.0.0-beta.3` and `1.0.0-beta.4` were tagged
with no `ReleaseNotes.md` section of their own (beta.3's tagged tree heads at
`## 1.0.0-beta.2`; beta.4's notes landed a day later in `687b532`). `verify-tag` reads
the *tagged tree* to catch this, and `.github/workflows/release.yml` re-asserts it after
any tag push.

**Release notes are a flat bullet list** — `* <desc> (#refs) by @user in <PR url>` — with
no `###` category subsections. Sections for beta.1–beta.4 predate this decision (made
2026-09-01) and were deliberately left un-flattened.

**The release PR is the merge-commit case**, unlike feature PRs — but the shape is
confirmed with the human each time rather than assumed. See
[[feedback_feature_pr_merge_squash_or_rebase]] and
[[feedback_check_merge_strategy_before_release_deletions]] (the archive tag is
load-bearing under squash).
