---
name: feedback_subrepo_directive_scope
description: "The subrepo-fixes directive governs subrepo-LOCAL hygiene only; cross-cutting changes that originate in the parent do belong on a parent branch"
metadata:
  node_type: memory
  type: feedback
---

`feedback_subrepo_fixes_belong_in_subrepo` is about **subrepo-local hygiene** —
a change concerning only content already inside the subrepo (the cited case is
CelestraCloud copyright headers). It does **not** block cross-cutting work that
originates in the parent repo and lands in a subrepo.

**Why:** Asked to move MistKit's `.claude/docs/` domain files into
`Examples/BushelCloud/` and `Examples/CelestraCloud/`, I read the directive as
forbidding it and put a false choice to Leo ("do it in the subrepo, or don't move
them"). He pushed back. The directive's own "How to apply" line carves this out:
*"only touch subrepo files when the change is part of that cross-cutting
concern"* — and the adjacent agent-notes line says repo-wide CI bumps DO extend
into the Examples subrepos in the same pass.

**How to apply:** Ask where the change *originates*. Originates inside the
subrepo and concerns only it → route to the standalone repo. Originates in the
parent, or decides what the parent owns → parent branch is correct; the only
real constraint is the mechanical one of getting it upstream later. Quote the
directive before invoking it. Related:
[[feedback_subrepo_fixes_belong_in_subrepo]],
[[project_examples_dir_is_for_mistkit_dev]].
