---
name: check-merge-strategy-before-release-deletions
description: "Before recommending deletions on a release branch, confirm the merge strategy — squash-merge means git history alone won't preserve removed content"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 9142d0cc-ddf5-4e22-b539-d1dd4f43093f
---

When planning to delete files from a release branch (e.g. removing WIP/internal artifacts before a release PR merges), explicitly ask about the merge strategy before assuming "git history preserves it forever."

**Why:** On 2026-05-17 I told Leo that deleting `docs/transcriptions/` and `docs/talk-feedback.md` from `v1.0.0-beta.1` was safe because the originating commits (`0ab2ab6`, `bce1f23`) would live on in git history. He corrected me: PR #298 is going to be squash-merged into `main`, which collapses the branch's commits into a single squash commit. Once `v1.0.0-beta.1` is deleted post-merge, the original commit SHAs are unreachable and eventually garbage-collected — meaning "git always remembers" is *false* under squash-merge. An archive branch or tag isn't optional ergonomics in that case; it's the only preservation mechanism.

**How to apply:** Whenever recommending deletion of files on a branch that's heading toward merge:
1. Ask (or check existing PR settings / repo defaults) whether the merge will be merge-commit, rebase, or squash.
2. For squash and rebase merges, treat preservation as load-bearing: push an archive branch AND ideally tag it before the deletion commit lands. Recommend the branch be protected (or at minimum, not part of the post-merge auto-delete sweep).
3. For true merge commits, git history alone is sufficient and an archive branch is just ergonomics.

Related: see also [[feedback_findings_to_issues_not_code]] — a deletion that surfaces "we should also preserve X" is a follow-up, not an excuse to expand scope mid-PR.
