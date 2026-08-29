---
name: GitHub Action pinning preference
description: For brightdigit-owned actions (e.g. brightdigit/swift-build), use major-version floating tags like @v1 rather than pinning to the latest patch (@v1.5.4)
type: feedback
originSessionId: d667433a-6b44-41ff-a056-470ceb1a865e
---
For GitHub Actions in MistKit CI workflows, when bumping `brightdigit/swift-build` (and likely other brightdigit-owned actions), use the major-version floating tag (`@v1`) rather than pinning to a specific patch (`@v1.5.4`).

**Why:** The user owns these actions and trusts their semver discipline; floating to `@v1` automatically picks up bug fixes without needing manual workflow edits per release. Pinning churn-prone third-party actions makes sense, but in-house actions are different.

**How to apply:** When updating CI workflows, default `brightdigit/swift-build` (and other brightdigit-namespaced actions) to `@v<major>`. Continue to pin third-party actions (codecov, sersoft-gmbh/swift-coverage-action, jlumbroso/free-disk-space, etc.) to specific majors or tags as appropriate. If unsure for a specific brightdigit action, ask.
