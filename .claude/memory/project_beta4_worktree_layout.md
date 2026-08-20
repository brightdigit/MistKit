---
name: project_beta4_worktree_layout
description: v1.0.0-beta.4 parallel issue work is split across git worktrees under MistKit.git/wt-<branch>, branch-per-issue-group
metadata:
  type: project
---

Milestone **v1.0.0-beta.4** remaining work (after PR #424 took #421/#378/#358/#295) is being developed in parallel git worktrees off the bare repo at `/Users/leo/Documents/Projects/MistKit/MistKit.git`, one worktree per issue *group*, all branched from `v1.0.0-beta.4` and PR'd back to that same base (not `main`).

Layout: `MistKit.git/wt-<branch-name>/`, branch named `##-issue-slug` (multi-issue groups join numbers, e.g. `41-42-records-resolve-accept`).

| Branch | Issues |
|---|---|
| `41-42-records-resolve-accept` | #41 `records/resolve`, #42 `records/accept` |
| `47-401-change-tracking-endpoints` | #401 umbrella, #47 `changes/zone`, #46 `changes/database` |
| `146-custom-zone-queries` | #146 |
| `386-zone-schema-metadata` | #386 |
| `398-399-mistdemo-phone-extensions` | #398, #399 |

Grouping rule used: issues touching the same `openapi.yaml` path family share a branch, since each one requires a `./Scripts/generate-openapi.sh` regeneration and separate branches would collide in `Sources/MistKitOpenAPI/`.

**#407 (MistKitConfiguration package) was deliberately excluded** — it is blocked on brightdigit/ConfigKeyKit#1 shipping and tagging, and it creates a new `Packages/` subrepo, which is not safe to do unattended.

Related: [[project_examples_dir_is_for_mistkit_dev]], [[feedback_subrepo_fixes_belong_in_subrepo]]
