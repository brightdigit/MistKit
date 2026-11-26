# Homogeneous `FieldValue.list` without a parallel enum?

**Date:** 2026-09-09  
**Issue:** [#481 — Make FieldValue.list homogeneous by construction](https://github.com/brightdigit/MistKit/issues/481)

## Question

Can MistKit avoid a parallel `ListValue` (or `FieldValue.List`) enum by using protocols, generics, type erasure, or another Swift shape — while still making heterogeneity and nesting unrepresentable, and while preserving MistKit’s load-bearing `default`-free conversion switches?

## Summary recommendation

**Protocols do not replace a closed kind set** for stored `FieldValue`. Prefer folding scalar-vs-list into each kind via `Arity<T>` (`.value` / `.list`) rather than a parallel `FieldValue.List` enum — one taxonomy, homogeneous lists, typed empty lists (`.string(.list([]))`).

**Migration polyfill (decided 2026-09-09):** deprecated static overloads for **single values only** (e.g. `string(_: String)` → `.string(.value(...))`). Call sites are almost all scalars. **No** polyfill for old `.list([FieldValue])` — list construction migrates to `.string(.list(...))` and breaks cleanly.

---

## Findings

### 1. What is actually duplicated?

#### Domain surface today

`FieldValue` is a single closed enum (`Codable`, `Equatable`, `Sendable`) with nine cases — eight leaf kinds plus a recursive list of `FieldValue` (`Sources/MistKit/Models/FieldValues/FieldValue.swift:33-42`):

| Domain case | Payload |
|---|---|
| `.string` / `.int64` / `.double` / `.bytes` / `.date` | scalar |
| `.location` / `.reference` / `.asset` | complex |
| `.list([FieldValue])` | **heterogeneous + nestable** |

CloudKit’s schema grammar is `LIST "<" primitive-type ">"` only — there is no `LIST<LIST<…>>` and no mixed-element list (`.claude/docs/sosumi-cloudkit-schema-source.md:47-63`, `.claude/docs/cloudkit-schema-reference.md:48-57`). So the domain case is **wider than the wire**.

#### Wire taxonomy (inevitable mapping)

Request `type` already enumerates both scalars and the granular list family (`openapi.yaml:1546`):

```text
STRING, INT64, DOUBLE, BYTES, TIMESTAMP, REFERENCE, ASSET, ASSETID, LOCATION,
STRING_LIST, INT64_LIST, DOUBLE_LIST, BYTES_LIST, TIMESTAMP_LIST,
REFERENCE_LIST, LOCATION_LIST, ASSET_LIST
```

Live S2S probe on `Note.tags` showed responses return `STRING_LIST` (and by implication the rest of the `*_LIST` family), including for empty `[]` (`.claude/memory/project_cloudkit_list_response_type_is_star_list.md`). `FieldValueResponse.type` in `openapi.yaml` was updated to match.

So CloudKit itself already has **two parallel name families** for the same eight primitives: `T` and `T_LIST`. A domain `List` enum that mirrors those eight kinds is aligning MistKit with the wire taxonomy, not inventing a second inventable taxonomy.

#### Conversion / filter switches (accidental workarounds on top of the gap)

| Site | What it assumes | Citation |
|---|---|---|
| `FilterBuilder.cloudKitListType(for:)` | Element type from `values.first` only; `.list` → `nil` (“let CloudKit reject”) | `FilterBuilder.swift:167-204` |
| `FieldValueRequest.init(list:)` | Lists sent **untagged**; no `TIMESTAMP_LIST` / `BYTES_LIST` on record writes | `Components.Schemas.FieldValueRequest.swift:129-133` |
| `ListValuePayload.init(from:)` | Nine-way `default`-free switch including nested `.list` | `ListValuePayload.swift:45-70` |
| Response list decode | Rebuilds `[FieldValue]` element-by-element; nested lists supported in code | `FieldValue+Components+List.swift:36-138` |
| `makeTypedComplex` | `LIST` validated at **container** only; “element types stay lenient” | `FieldValue+Components.swift:151-154` |
| `ResponseTypeTag` | Maps response `_typePayload` with a `default`-free switch; only `.LIST` today | `FieldValue+ResponseTypeTag.swift:55-66` |

**Classification of “duplication”:**

| Kind | What it is | Verdict |
|---|---|---|
| **(a) Domain API surface** | Parallel cases `string` vs `strings([String])`, etc. | Real, intentional once lists are homogeneous-by-construction — same as CloudKit’s `STRING` vs `STRING_LIST` |
| **(b) Inevitable wire mapping** | Domain kind ↔ OpenAPI `_typePayload` / `ListValuePayload` / generated oneOf | Cannot be removed; OpenAPI types are non-generic enums |
| **(c) Accidental** | First-element guessing, nested-list encode path, lenient element validation, untagged list writes | Removable *by* a closed homogeneous list type + total switches — not by protocols alone |

Issue #481’s claim that the invariant is “already assumed in three places” is accurate; those sites are workarounds, not a second independent design.

### 2. Protocol-oriented / generic alternatives (evaluated for this codebase)

#### A. `protocol ListElement` + `HomogeneousList<Element: ListElement>`

Sketch:

```swift
protocol ListElement: Codable, Equatable, Sendable {
  static var cloudKitListType: Components.Schemas.FieldValueRequest._typePayload { get }
}
struct HomogeneousList<Element: ListElement>: Codable, Equatable, Sendable {
  var values: [Element]
}
```

**What this buys:** At a *typed* call site (`HomogeneousList<String>`), homogeneity is compile-time.

**What it does not buy for `FieldValue`:** `FieldValue` must remain a **single** non-generic type so records can be `[String: FieldValue]` and conversion can `switch` exhaustively. You cannot write a per-case generic:

```swift
// Not legal Swift — cases do not introduce their own generic parameters.
enum FieldValue {
  case list<Element: ListElement>(HomogeneousList<Element>)
}
```

Generics attach to the **enum type**, not to individual cases ([Swift Forums pitch “Enum with generic cases”](https://forums.swift.org/t/enum-with-generic-cases/5760) — still an unimplemented pitch; language today requires `enum FieldValue<Element> { … }`). Making all of `FieldValue` generic breaks the heterogeneous field map and every conversion boundary.

So `HomogeneousList<Element>` only helps as a **helper** behind factories (`FieldValue.list(["a","b"])`), not as the stored associated value of `.list` unless you erase it.

#### B. Nested `FieldValue.List` as generic vs enum

- **Generic nested type** `FieldValue.List<Element>`: same problem — cannot store `List<String>` and `List<Int>` in one non-generic `FieldValue` without erasure.
- **Enum nested type** `FieldValue.List` with eight cases: this **is** the #481 proposal (naming preference in the issue’s open questions). It preserves exhaustiveness and forbids nesting (no `case lists`).

#### C. Existential `[any ListElement]`

[SE-0309](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0309-unlock-existential-types-for-all-protocols.md) unlocked using protocols with associated types as existentials; [SE-0346](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md) / [SE-0353](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0353-constrained-existential-types.md) add constrained existentials like `any Collection<String>`.

For a marker `ListElement` **without** a primary associated type that pins the element to one concrete type, `[any ListElement]` is exactly **heterogeneous again** — `.list([.string("a") as any ListElement, 1 as any ListElement])` type-checks if both conform. That restores the bug #481 exists to delete.

Constrained existentials (`any ListElement where …`) do not give “array of one concrete element kind chosen at runtime but fixed per value” without either:

- a generic wrapper (back to A), or  
- a closed set of concrete list types (back to an enum / type erasure over that set).

#### D. Phantom-typed wrappers

`struct ListOf<Tag> { let values: [Tag.Element] }` still needs a non-generic sum type to embed in `FieldValue`. Phantoms do not shrink the closed set of CloudKit list kinds; they only move the tag into the type system for *callers who already know the tag*.

#### E. Can `FieldValue` grow a generic list case?

**No, usefully.** Either:

1. `enum FieldValue<E>` — entire value becomes mono-kind; unusable as a CloudKit field dictionary value; or  
2. Fixed `case list(HomogeneousList<String>)` — only string lists; or  
3. Eight list cases / one list enum — which is the parallel enum.

Swift’s enumeration model documents associated values per case, but generics are parameters of the type ([TSLP Enumerations](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/)); there is no shipped SE that adds per-case generics.

#### F. Type-erased `AnyFieldValueList`

```swift
struct AnyFieldValueList: Codable, Equatable, Sendable {
  // must store kind + bytes or an inner enum anyway
}
```

To implement `Equatable` / `Codable` / `Sendable` and a total `cloudKitListType`, the box **contains** a closed kind discriminant. That is the parallel enum with extra indirection. Exhaustive `switch` on `FieldValue` no longer sees element kinds unless you switch on the box’s inner enum — so conversion sites either gain `default`/`as?` paths or reintroduce the enum API publicly.

Synthesized `Codable` for enums with associated values is available ([SE-0295](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md)); existentials and hand-rolled type erasers typically need custom `Codable`, which fights MistKit’s “domain enum is the source of truth” pattern.

### 3. What breaks against MistKit’s hard constraints?

| Constraint | Protocol / existential approach | Closed `FieldValue.List` enum |
|---|---|---|
| `FieldValue: Codable, Equatable, Sendable` public | Existential arrays / type erasers need custom Codable/Equatable; easy to get wrong | Straightforward nested enum; same conformances as today |
| `default`-free switches at request / list payload / FilterBuilder / response tag | Erasure forces runtime casts or a second discriminant; new kinds can slip through | Compiler forces every boundary when a case is added — same instinct as `FieldValueRequest.init(from:)` (`FieldValueRequest.swift:44-46`) |
| OpenAPI generated types are non-generic | Still need a total map from domain → `_typePayload` / `ListValuePayload` | Direct case → tag mapping |
| IN/NOT_IN needs total `*_LIST` tag | Static protocol requirement can supply the tag **per concrete type**, but FilterBuilder today takes `[FieldValue]` / would take erased lists — back to first-element or inner enum | `switch list` is total; empty lists still need a chosen case or schema-known type (probe: response recovers type via `STRING_LIST`) |
| Nested lists forbidden | Protocol does not forbid `ListElement` = some list type unless carefully constrained; easy to get wrong | No `lists` case → unrepresentable |
| Pre-1.0 source break OK; silent heterogeneity not | Existential storage fails the second requirement | Passes |

`feedback_no_silent_policy_defaults.md` is about non-defaulted *policy* parameters, not enums — but the same ethic applies: a runtime check that “usually” enforces homogeneity is a silent policy. #481 correctly rejects `case list(ElementKind, [FieldValue])` for that reason.

### 4. Hybrid designs that reduce *maintenance* duplication without losing exhaustiveness

| Hybrid | Effect | Fit for #481 |
|---|---|---|
| **Closed `FieldValue.List` enum (eight cases)** | Homogeneous + non-nestable by construction; total tag mapping | **Primary approach** |
| **Shared internal “element kind → wire” tables** | One place maps kind → `*_LIST` / payload builder; scalars and lists call into it | Good *refactor*, orthogonal to public shape |
| **Single source-of-truth `ElementKind` enum** used by both scalar cases and list | Still need payloads (`String` vs `[String]`); often *more* types, not fewer | Optional internal; weak as public API |
| **Macro / codegen** to emit scalar + list cases + switches | Reduces edit drift; does not change the semantic model | Optional later; overkill for eight fixed CloudKit kinds |
| **`case list(ElementKind, [FieldValue])` + runtime assert** | Appears DRY; heterogeneity still representable; fails silent-heterogeneity rule | **Reject** (as #481) |
| **Protocols only on factories** (`static func list(_:[String]) -> FieldValue`) | Ergonomics without storing existentials | Compatible with enum approach |

**Why protocols do not remove the duplicate enum:** each `ListElement` conformance re-states “this Swift type is CloudKit kind X and encodes like Y” — the same information as a `case strings`. The existential/type-eraser then re-states the closed set again so `FieldValue` can hold it. Net duplication **increases** (conformances + box + conversion casts) while exhaustiveness **decreases**.

### 5. Empty lists and naming (from issue + probe)

- Live probe: empty `[]` round-trips **present**, tagged `STRING_LIST`. Decode does **not** require `case empty` once response openapi accepts `*_LIST` (`.claude/memory/project_cloudkit_list_response_type_is_star_list.md`).
- Naming: generated `Components.Schemas.ListValue` / `ListValuePayload` already exist. Prefer **`FieldValue.List`** (issue open question) so domain vs wire stay legible.
- `ASSETID`: response tag shares `AssetValue` with `ASSET` (`FieldValue+ResponseTypeTag.swift:52-63`); no separate list case — request family has `ASSET_LIST` only (`openapi.yaml:1546`).

---

## Alternatives compared

| Approach | Homogeneous by construction? | Nesting forbidden? | Exhaustive switches? | Fits non-generic `FieldValue`? | Codable/Equatable/Sendable | Verdict |
|---|---|---|---|---|---|---|
| Keep `[FieldValue]` | No | No | Yes (but wrong model) | Yes | Yes | Status quo — reject |
| **`FieldValue.List` enum (8 cases)** | Yes | Yes | Yes | Yes | Yes | **Use this** |
| `HomogeneousList<E: ListElement>` only | Yes at typed sites | If constrained | N/A alone | **No** without erasure | Yes for concrete E | Helper only |
| `[any ListElement]` | **No** | No | Weak | Yes | Painful | **Don’t use** |
| `AnyFieldValueList` box | Only if box hides an enum | Only if box forbids | Only via inner enum | Yes | Custom | Enum with extra junk — **don’t use** as public model |
| Generic `FieldValue<E>` | Per-field only | Possible | Awkward | **Breaks** field maps | Yes | **Don’t use** |
| `(ElementKind, [FieldValue])` + runtime check | No (runtime only) | Runtime only | Kind yes, elements no | Yes | Yes | **Don’t use** |
| Macro-emitted parallel cases | Yes | Yes | Yes | Yes | Yes | Optional tooling later |

---

## Recommendation detail

**Use this** (updated 2026-09-09 after Arity discussion)

1. Replace scalar cases + `case list([FieldValue])` with **one case per CloudKit kind** carrying `Arity<T>` (`.value` / `.list`). Removes the parallel list enum and makes empty lists typed (`.string(.list([]))`).
2. **Deprecated scalar polyfills only** — `static func string(_: String)`, `int64(_: Int)`, … marked `@available(*, deprecated)` forwarding to `.value`. No `.list([FieldValue])` shim; heterogeneous list construction breaks cleanly (pre-1.0; matches issue + `feedback_available_semantics.md`).
3. Make request/response/`cloudKitListType` mapping **total** on `(kind, arity)`.
4. Optionally factor shared kind→wire helpers internally; do not use protocols as storage.
5. Pattern matches are not polyfilled — update to `.string(.value(let s))` / accessors.

**Don’t use that**

- Protocols + existentials as the **stored** list representation.
- Type-erased public boxes that re-hide an enum.
- Runtime-checked heterogeneous `[FieldValue]` / deprecated `list([FieldValue])` polyfill.
- Making `FieldValue` itself generic.
- Parallel `FieldValue.List` enum — superseded by `Arity` unless implementation hits a blocker.

**Open questions left for implementation (not blocked by this research)**

- Public name for the wrapper: `Arity` vs `FieldValue.SingularOrList` vs nested `FieldValue.Value`.
- How aggressively to tag **record-field** list writes with `*_LIST` (IN/NOT_IN already need tags; record writes currently omit list tags — `FieldValueRequest.swift:129-133`).
- Whether deprecated scalar factories stay through 1.0 or are beta-only.
- Deprecate-flatten `listValue: [FieldValue]?` vs only typed accessors.

---

## What this does NOT decide

- Fixing `FieldValueResponse.type` in `openapi.yaml` from flat `LIST` to the live `*_LIST` family (probe-confirmed; blocks decoding today). That is **required for honest list reads** and unlocks empty-list type recovery, but it is an OpenAPI/generated-client change adjacent to #481, not answered by the protocol-vs-enum question.
- Whether DocC articles (`WhatCloudKitGotWrong`, `FieldTypePolymorphism`) that still describe response `LIST` as live truth should be refreshed after the openapi fix — they are superseded on the wire by the 2026-09-09 probe.
- Concrete migration of Examples / MistDemo formatters / test renames (issue checklist).
- Implementing homogeneous lists — research only.

---

## Sources

**In-repo**

- GitHub issue #481 body + empty-list probe comment  
- `Sources/MistKit/Models/FieldValues/FieldValue.swift`  
- `Sources/MistKit/Models/FieldValues/FieldValue+Components.swift`  
- `Sources/MistKit/Models/FieldValues/FieldValue+Components+List.swift`  
- `Sources/MistKit/Models/FieldValues/FieldValue+ResponseTypeTag.swift`  
- `Sources/MistKit/Models/FieldValues/FieldValue+Convenience.swift`  
- `Sources/MistKit/OpenAPI/Components/Components.Schemas.FieldValueRequest.swift`  
- `Sources/MistKit/OpenAPI/Components/Components.Schemas.ListValuePayload.swift`  
- `Sources/MistKit/Models/Queries/FilterBuilder/FilterBuilder.swift`  
- `openapi.yaml` (~1525–1576)  
- `.claude/docs/cloudkit-schema-reference.md`, `.claude/docs/sosumi-cloudkit-schema-source.md`  
- `.claude/memory/project_cloudkit_list_response_type_is_star_list.md`  
- `.claude/memory/feedback_no_silent_policy_defaults.md`  
- CLAUDE.md FieldValue architecture; DocC `WhatCloudKitGotWrong` / `FieldTypePolymorphism` (context; response-`LIST` claim outdated vs probe)

**Swift / language**

- [The Swift Programming Language — Enumerations](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/)  
- [SE-0309 Unlock existential types for all protocols](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0309-unlock-existential-types-for-all-protocols.md)  
- [SE-0346 Light-weight same-type syntax](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0346-light-weight-same-type-syntax.md)  
- [SE-0353 Constrained existential types](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0353-constrained-existential-types.md)  
- [SE-0295 Codable synthesis for enums with associated values](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md)  
- [Swift Forums: Enum with generic cases (unimplemented pitch)](https://forums.swift.org/t/enum-with-generic-cases/5760)  
