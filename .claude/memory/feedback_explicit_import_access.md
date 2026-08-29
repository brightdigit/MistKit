---
name: Explicit access modifier on every import
description: All imports in MistKit must declare an access modifier explicitly — write `internal import Foo` rather than bare `import Foo`
type: feedback
originSessionId: 4f252cd5-67e2-461b-86a4-62b835459c8d
---
When changing or adding imports in MistKit, every `import` statement must
have an explicit access modifier (`public import`, `internal import`,
`private import`, `fileprivate import`). Bare `import Foo` is not allowed
even though it would default to `internal`.

**Why:** the package enables the `InternalImportsByDefault` upcoming
feature in `Package.swift`. Bare imports compile but the project convention
is to be explicit so the access intent is visible at the import site rather
than implicit from a Package-level setting.

**How to apply:** when downgrading `public import Foo` (because Foundation
isn't used in public declarations), replace with `internal import Foo` —
not bare `import Foo`. Same when adding any new import.
