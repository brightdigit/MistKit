---
name: reference-draft-gated-ci-needs-ready-for-review
description: "A workflow job gated on `draft == false` needs `types: [..., ready_for_review]`, or it stays skipped forever and never guards the transition it exists for."
metadata:
  type: reference
---

A job guarded by `if: github.event.pull_request.draft == false` evaluates that
condition against **the payload of the event that queued the run**, not against
the PR's state at read time.

`on: pull_request` without an explicit `types:` defaults to
`[opened, synchronize, reopened]` — **none of which fire when a draft is marked
ready for review**. So a PR opened as a draft keeps its draft-time evaluation
and reports `skipped` indefinitely.

Two things that do *not* fix it:

- **Re-running the workflow** — a re-run replays the original event payload, so
  the condition re-evaluates to the same stale `draft: true`.
- **Toggling draft → ready → draft** — that emits `ready_for_review` /
  `converted_to_draft`, which the default `types:` ignores.

The failure mode is silent and inverted: the gate shows `skipped`, never
`failure`, so a PR can go draft → merged with exactly the dependencies the gate
exists to reject. Observed on `brightdigit/MistKitConfiguration`
`dependency-policy.yml` (2026-08-31, PR #1); fixed by adding
`types: [opened, synchronize, reopened, ready_for_review]`.

**Apply:** any `draft == false` gate must list `ready_for_review` in `types:`.
When a required check reads `skipping` on a PR that is *not* a draft, treat it
as a broken gate, not a pass — verify the check's logic locally before merging.

Related: [[project_mistkitconfiguration_subrepo_overlay]]
