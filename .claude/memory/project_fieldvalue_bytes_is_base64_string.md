---
name: project_fieldvalue_bytes_is_base64_string
description: FieldValue.bytes holds a base64 String (not Data) to mirror the wire format; changing it to Data is specced in #467
metadata:
  type: project
---

`FieldValue.bytes` is `case bytes(String)` — a **base64-encoded string**, not `Data`
(`Sources/MistKit/Models/FieldValues/FieldValue.swift`).

**There is no recorded rationale for this.** The case arrives fully formed in `d11c6c5`
("v1.0.0 beta.1", #298), which squashes the entire pre-beta history, and nothing in the
issue tracker, `ReleaseNotes.md`, or this memory store deliberates it. Don't go looking
again — this file *is* the answer to "why String?".

The de facto reasons visible in the code:

1. It mirrors the wire 1:1 — `openapi.yaml` defines `BytesValue` as `type: string`
   ("Base64-encoded string"), and the generated `BytesValue` is `typealias … = Swift.String`.
2. It keeps the conversion layer total: `.string` and `.bytes` share a `String` payload, so
   several switch arms collapse into one (`FieldValue+Codable.swift`,
   `ScalarPayload.text`/`.inferred` in `FieldValue+Components+Scalar.swift`). With `Data`,
   every decode site gains a fallible `Data(base64Encoded:)` step.

Cost: `bytesValue` returns `String?` and there is **no** `Data` bridge anywhere in
`Sources/MistKit/` — callers hand-roll the decode.

**Changing it to `Data` is specced in issue #467** (decisions settled there: reuse
`ConversionError.typeValueMismatch` rather than a new case; untagged base64 keeps
resolving to `.string`; `dataValue` stays a strict `.bytes`-only match).

## Base64 has no false-positive signal

Load-bearing for #467, and worth knowing generally: base64 carries no header, checksum,
or self-identifying structure. Validity is only a character-set-and-length check, so **any**
`[A-Za-z0-9+/]` string whose length is a multiple of 4 decodes successfully:

| Input | `Data(base64Encoded:)` |
|---|---|
| `"test"`, `"user"`, `"name"`, `"true"`, `"data"`, `"Chen"` | 3 bytes of garbage |
| `"hello"` (len 5), `"Mei"` (len 3) | `nil` |

`"Chen"` is from Apple's own example record (`.claude/docs/webservices.md`,
`"lastName" : {"value" : "Chen"}`) — a four-letter surname is indistinguishable from base64.

**Therefore: never infer `.bytes` by attempting a base64 decode**, neither in the scalar
decode chain nor as a `dataValue` fallback for `.string`. A non-`nil` result proves only
that a string *could* be base64, never that it *is*; inference would hand back
plausible-looking garbage instead of a visible failure.

## Untagged BYTES responses — frequency unmeasured

When a response omits `type`, first-match-wins inference claims a base64 string as
`.string` (documented in CLAUDE.md as lossy). How often CloudKit actually omits `type` on
reads is **not established**: our `openapi.yaml` calls it optional, but that wording is
*ours*, hand-written from Apple's docs — and Apple's authoritative `Record Field Dictionary`
is referenced at `.claude/docs/webservices.md` without its definition being included in the
offline copy. Note "optional in the schema" ≠ "sometimes absent in practice". No captured
live responses exist in the repo; every `"type"` in the tests is a hand-written fixture.

Settle it the way #430 settled `metaSyncToken` — against a live container
(`swift run mistdemo create` with a bytes field, then a `.debug` query) — before treating
untagged binary as either real or theoretical.

Related: [[project_release_process]]
