---
name: project-mistkit-branch-pin-resolves-tags
description: "MISTKIT_BRANCH in example workflows is resolved with `git ls-remote`, which matches tags too — a tag value silently pins the old release and makes example CI green without testing the branch"
metadata:
  node_type: memory
  type: project
---

`MISTKIT_BRANCH` in the `Examples/*/.github/workflows/*.yml` workflows is fed to the
`setup-mistkit` action, which resolves it via
`git ls-remote https://github.com/brightdigit/MistKit.git "$BRANCH"`. That command
matches **tags as well as branches**, and MistKit tags (`1.0.0-beta.3`) differ from its
branch names (`v1.0.0-beta.4` — note the `v` prefix) by exactly one character.

**Why:** A tag value therefore resolves successfully and pins by `revision:` with no
warning — the workflow does not fall back or fail. On 2026-08-29, CelestraCloud PR #56
was pinned to `1.0.0-beta.3`, a *tag* equal to `main`, so its CI passed green while never
compiling against the `v1.0.0-beta.4` code the PR existed to validate. A green example PR
is not by itself evidence that the branch under development builds.

**How to apply:** When pushing example subrepos for a MistKit branch, check that each
workflow's `MISTKIT_BRANCH` is the **branch** name (with the `v` prefix), not a release
tag. Confirm from a build log that `Setup MistKit` printed
`Pinning MistKit to <branch> @ <sha>` with a sha matching the branch tip. Also note the
examples use `.package(name: "MistKit", path: "../..")`, which only resolves inside this
monorepo — a build job with **no** `Setup MistKit` step fails standalone with
`the package manifest at '.../Package.swift' cannot be accessed`. See
[[project_examples_dir_is_for_mistkit_dev]] and [[feedback_setup_action_lives_in_owned_repo]].
