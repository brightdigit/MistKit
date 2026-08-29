---
name: feedback_record_result_pattern_throughout
description: "Per-item operation results should use the RecordResult success-or-failure pattern across ALL modify APIs, not just records"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4fd0d5d3-b3f5-4ec2-a4ab-876f2ae8272f
---

Batch/modify operations that can return per-item failures must surface them with
the same `RecordResult` success-or-failure pattern records use (`RecordResult` +
`RecordOperationFailure`, modeled in openapi.yaml as `oneOf: [<Failure>, <Success>]`
on the response array). Apply this consistently throughout the API —
subscriptions, zones, etc. — not as a one-off per operation.

**Why:** CloudKit returns per-item errors inline in 200 modify responses (e.g.
`{subscriptionID, reason, serverErrorCode}`). Operations that don't model a
failure variant (subscriptions/modify did not) silently drop errored entries —
`modifySubscriptions` returned an empty array where CloudKit JS showed a visible
`INTERNAL_ERROR`. Records get this right; the rest of the API should match.

**How to apply:** when adding/auditing a modify-style operation, model a
`<Thing>OperationFailure` schema (id + serverErrorCode + reason), make the
response items `oneOf: [<Thing>OperationFailure, <Thing>]`, regenerate, and
return a `RecordResult`-style result the caller can inspect — never compactMap
the failures away. See [[feedback_no_silent_policy_defaults]] and
[[feedback_findings_to_issues_not_code]] for related scope/safety norms.
