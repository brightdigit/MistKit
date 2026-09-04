---
name: project-dogfood-pins-are-branch-pins-not-tags
description: "Examples keep path: deps for BOTH MistKit and MistKitConfiguration; CI rewrites both to branch-HEAD revision pins. Releasing MistKitConfiguration does NOT mean the Examples switch to its tag."
metadata:
  type: project
---

Tagging MistKitConfiguration does **not** mean `Examples/*/Package.swift` should
switch to `from: "<tag>"`. The Examples exist to dogfood **unreleased** MistKit, so
they must reach every in-monorepo package the same way: `path:` locally, rewritten
to a **branch-HEAD `revision:` pin** in CI.

`.github/actions/setup-mistkitconfiguration` (in the MistKitConfiguration repo)
already does exactly this — it takes `mistkit-branch` **and**
`mistkitconfiguration-branch` and rewrites *both* path deps in one pass. Its own
description states the constraint: *"a path: MistKit and a url: MistKit cannot
coexist."*

**Why a tag is the wrong lever here.** Pointing only MistKitConfiguration at a tag
breaks the Examples two ways, both verified 2026-08-31:

1. Tagged MistKitConfiguration depends on MistKit by `url:`, which collides with the
   Examples' sibling `path:` MistKit — the duplicate-target failure in
   [[project_path_package_identity_collision]]. Appears at `swift build`, not
   `resolve`.
2. Resolving that by *also* moving MistKit to its released tag makes MistDemo fail to
   compile: it uses `ZoneType` and `ZoneInfo.deleted` (issue #444), which exist only
   on the development branch. Building an Example against the last release defeats
   the point of `Examples/`.

So the release train and the dogfood wiring are independent. A published tag is for
**downstream consumers**; the Examples stay on branch pins until the feature they
exercise has actually shipped.

**Apply:** when a monorepo package gets tagged, leave `Examples/*/Package.swift`
alone. If an Example lane needs the collision resolved in CI, add
`setup-mistkitconfiguration` with both branch inputs rather than rewriting manifests.

Related: [[project_examples_dir_is_for_mistkit_dev]],
[[project_mistkitconfiguration_subrepo_overlay]],
[[feedback_setup_action_lives_in_owned_repo]]
