---
name: feedback-ci-only-flake-gate
description: "Test gates for CI-induced flakes (cooperative-executor races on visionOS/watchOS sim, etc.) must check ProcessInfo.processInfo.environment[\"CI\"] in addition to platform, so local sim runs stay strict"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ded31425-8f17-4a10-8ba7-7567c5299eb1
---

When gating tests around flakes that only manifest under CI load (e.g. simulator cooperative-executor races in `withTimeout`), combine the platform check with `ProcessInfo.processInfo.environment["CI"] != nil`. Don't gate on platform alone.

**Why:** A developer running a focused test locally against a visionOS / watchOS simulator should still see strict assertions — that's where they'll catch regressions in `withTimeout` itself. The race the gate exists for is bounded to CI load (heavily oversubscribed runners), not the platform's executor in isolation. Gating on platform alone silently makes the local run permissive too.

**How to apply:** When adding helpers like `TestPlatform.isFlakyTimeoutSimulator` (#334) or similar "this is expected to be unreliable here" predicates, AND-in `ProcessInfo.processInfo.environment["CI"] != nil`. `CI=true` is the GitHub Actions / standard convention; presence is sufficient.

Related: [[feedback-conditional-known-issue-overload]] — pair the CI-gated boolean with a `withKnownIssue(when:)` overload, not an if/else around the body.
