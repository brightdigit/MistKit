---
name: project-examples-dir-is-for-mistkit-dev
description: "Examples/ subdirectory (BushelCloud, CelestraCloud) exists to dogfood MistKit during its own development; deployment patterns specific to that arrangement don't generalize to end users"
metadata: 
  node_type: memory
  type: project
  originSessionId: d32a513b-ec52-4df2-b35f-b00a7cd3d6bf
---

The `Examples/BushelCloud/` and `Examples/CelestraCloud/` directories in the MistKit repo are MistKit's own integration testbeds - they get pulled in via `Examples/` so MistKit changes can be exercised against real workloads. Things like `MISTKIT_BRANCH: v1.0.0-beta.1` in CelestraCloud's GitHub Actions workflow exist to test MistKit-under-development, not as a recommended deployment pattern for end users.

**Why:** When writing user-facing docs that cite these examples, don't promote MistKit-development-only mechanics (branch pinning via env, the `setup-mistkit` action wiring, `.gitrepo` files, etc.) as patterns end users should adopt - end users consuming MistKit via SPM just use standard `Package.swift` version constraints.

**How to apply:** When drafting tutorials/blog posts that reference the Examples/, treat the GitHub Actions workflows there as illustrative of the *deployment shape* (cron, secrets, binary caching, reporting) but skip over the MistKit-dogfooding-specific bits unless the article is explicitly about contributing to MistKit. See [[feedback_findings_to_issues_not_code]] for the general "stay in scope" instinct.
