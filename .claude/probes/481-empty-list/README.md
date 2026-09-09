# Probe: how does CloudKit represent an **empty** list field? (issue #481)

**Status: BLOCKED — needs a schema change to the MistDemo container.**

## Why this question matters

Issue #481 replaces `FieldValue.list([FieldValue])` with a homogeneous payload
(`FieldValue.List`). The one design decision that changes the shape of the public type is
how to represent an **empty** list:

- The response `type` enum carries a single flat `LIST` (`openapi.yaml:1573`), **not** the
  granular `*_LIST` family that requests use (`openapi.yaml:1546`). So a tagged list
  response says "this is a list" and nothing about its element type.
- For a non-empty list that is fine — elements are self-describing by shape, so the element
  type is recovered from the first element (this is what `FilterBuilder.cloudKitListType(for:)`
  already does, `FilterBuilder.swift:170-203`).
- For an **empty** list, `[]` carries no elements to inspect and the container tag names no
  element type. **We have no hint about the element type on the way back.**

So: does an empty list field come back as `[]`, come back **absent**, or fail to write at
all? That determines whether `case empty` is the only honest decode target, or merely
defensive.

## What was actually established (2026-09-09)

Two live runs against `iCloud.com.brightdigit.MistDemo`, `development`, public DB,
server-to-server auth. Both failed with `BAD_REQUEST`:

| Written | Server response |
|---|---|
| `.list([])` | `Field probeEmptyList not found in Note` |
| `.list([.string("a"), .string("b")])` | `Field probeFilledList not found in Note` |

**The second row is the load-bearing one.** The *populated* list was rejected too, so this
container does **not** auto-create schema fields on write. The failures therefore say
nothing about empty lists specifically — they only say the field is absent from the schema.

**Conclusion: the question is UNRESOLVED.** Do not cite these runs as evidence that
CloudKit rejects empty lists. They show only that `Note` has no list field.

Nothing was written to the container — both writes were rejected server-side.

## Why it is blocked

`Note` (`Examples/MistDemo/schema.ckdb`) has **no list field of any type**:

```
RECORD TYPE Note (
    "title"   STRING QUERYABLE SORTABLE SEARCHABLE,
    "index"   INT64 QUERYABLE SORTABLE,
    "image"   ASSET,
    ...
);
```

Probing requires adding one, which means `cktool import-schema` against a **real shared
container** that MistDemo's integration phases run against. That needs a management token
(not present in `MistDemo.env`, not in the keychain — `cktool export-schema` reports
`No management token found`), and it is an outward-facing change, so it was not done
unprompted.

## How to resume

1. **Get a management token**: `xcrun cktool save-token` (Apple Developer portal →
   CloudKit management token), or set `CLOUDKIT_MANAGEMENT_TOKEN`.
2. **Add a list field to `Note`** in `Examples/MistDemo/schema.ckdb`:
   ```
   "tags"  LIST<STRING>,
   ```
   Development-environment schema additions are additive; verify first with
   `xcrun cktool validate-schema`.
3. **Push it**:
   ```bash
   xcrun cktool import-schema --team-id <TEAM> \
     --container-id iCloud.com.brightdigit.MistDemo \
     --environment development \
     --file Examples/MistDemo/schema.ckdb
   ```
4. **Point `probe.swift` at the real field** — rename `probeEmptyList`/`probeFilledList` to
   the field(s) you added (a single `tags` field, written once empty and once populated, is
   enough).
5. **Run it** from a scratch package that depends on this branch:
   ```swift
   // Package.swift
   dependencies: [.package(path: "<path to this worktree>")],
   targets: [.executableTarget(name: "probe",
       dependencies: [.product(name: "MistKit", package: "481-fieldvalue-homogeneous-list")])]
   ```
   ```bash
   swift run probe
   ```
   `probe.swift` reads credentials directly from `MistDemo.env` at the repo root.

## What each outcome means for the design

| Empty list reads back as | Implication for `FieldValue.List` |
|---|---|
| `[]` (present, no type hint) | `case empty` is **required** — it is the only value the decoder can honestly produce. |
| **absent** from the record | `case empty` is harmless but never produced on read; still needed to *write* an empty list. |
| write rejected outright | Empty lists are not expressible; consider forbidding them at construction instead. |

**Design decision taken in the meantime:** ship `case empty`. It is correct under all three
outcomes — it costs one switch case if empty lists turn out to be absent-on-read, and it is
the only correct answer if they come back as `[]`. Avoids inventing an element type the wire
never supplied (cf. `.claude/memory/feedback_no_silent_policy_defaults.md`).

Record this result in issue #481 and in `.claude/memory/` once established.
