---
name: Test parent type — enum vs struct
description: Use internal enum for hierarchical (multi-file) test parents, internal struct for simple (single-file) test types
type: feedback
originSessionId: 5be456ed-33a6-4840-b161-f4d22e3f47a5
---
When organizing Swift Testing suites in MistKit / MistDemo, the parent type's keyword depends on whether the type-under-test has its tests split across multiple files:

- **Multiple test files for one type-under-test → `internal enum ParentTests {}`** (empty container) plus `extension ParentTests { internal struct Category { ... } }` in separate files.
- **Single test file for the type → `internal struct ParentTests { ... }`** with the tests inline.

Do not convert a struct parent to an enum just because the guide allows enum. Only convert when the type genuinely requires splitting across files (≥10 tests *and* multiple categories).

**Why:** Empty enums add ceremony for no benefit when there's nothing to nest in them. The enum pays off only when you have category extensions in sibling files. User stated: *"For D only convert Struct to Enum if the type being tested requires multiple test files."*

**How to apply:**
- During reorganization (e.g. issue #261), evaluate each test file: if it has multiple `// MARK:` sections AND >10 tests, split into hierarchical (enum + extensions). Otherwise leave as a simple struct.
- When normalizing existing MistKit hierarchical files (LoggingMiddlewareTests, CustomFieldValueTests), the parent becomes `enum` only because each already has sibling extension files. If you were collapsing one of those back to a single file, it would become `struct`.
- The `Tests` suffix rule still applies: parent name carries `Tests`, child struct names do not (Pattern A from `.claude/docs/test-organization-guide.md`).
