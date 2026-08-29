---
name: feedback_subrepo_fixes_belong_in_subrepo
description: "Fixes scoped to a subrepo's own content (e.g. CelestraCloud copyright headers) should be done directly in that subrepo's repo, not in a parent MistKit branch"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 80198061-8586-400f-ab37-cd6779a95fc8
---

When a fix only concerns content inside a git-subrepo Example (e.g. bumping copyright headers in CelestraCloud, or any change isolated to that package), do it directly in the standalone subrepo's own repository — not on a parent MistKit branch that would later need a `git subrepo push`.

**Why:** The Examples (BushelCloud/CelestraCloud) are git subrepos with their own CI, header identity (creator/company/package strings), and PRs. Editing them from the parent couples unrelated changes and fights the subrepo workflow. (Concretely: issue #320's copyright bump was pulled out of a docs-sync branch and routed to the CelestraCloud repo where PR #331 already lived.)

**How to apply:** During cross-cutting tasks (e.g. release-prep doc sync), only touch subrepo files when the change is *part of* that cross-cutting concern (e.g. a stale MistKit version reference). Subrepo-local hygiene unrelated to the parent task → flag it and direct it to the subrepo's repo instead. Related: [[project_examples_dir_is_for_mistkit_dev]], [[feedback_setup_action_lives_in_owned_repo]].
