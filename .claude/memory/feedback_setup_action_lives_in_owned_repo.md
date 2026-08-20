---
name: setup-action-lives-in-owned-repo
description: "A setup-X GitHub action lives in repo X itself, not in consuming repos; consumers reference it as `brightdigit/X/.github/actions/setup-X@main`"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d1a72739-76ad-474a-b439-878e9f9f41e3
---

When a GitHub composite action's job is to rewrite a Swift package dependency on package X (swap a local `path:` for a remote `url:` / branch), that action belongs in **repo X**, not in the consuming repo.

**Why:** This is how `setup-mistkit` already works — it lives in `brightdigit/MistKit/.github/actions/setup-mistkit/` and BushelCloud / CelestraCloud workflows reference it as `brightdigit/MistKit/.github/actions/setup-mistkit@main`. The action ships alongside the package it knows how to rewrite, so consumers don't all maintain duplicate copies.

**How to apply:** When designing a new `setup-<package>` action during an extract-to-subrepo migration (e.g. ConfigKeyKit from MistKit, future similar splits), place the action in the *extracted* repo, not in the source repo. Consumer workflows reference it remotely. Don't propose adding it to MistKit just because MistKit happens to be where the migration originates.
