---
name: OpenAPI extension filename convention
description: For new files in Sources/MistKit/Extensions/OpenAPI/, omit the +MistKit suffix; use bare TypeName.swift
type: feedback
originSessionId: b6d820bb-ff7e-425b-a149-8cf2a85e9fe8
---
For new bridging-extension files in `Sources/MistKit/Extensions/OpenAPI/`, name them `<FullyQualifiedType>.swift` — drop the `+MistKit` suffix.

**Why:** The directory itself (`Extensions/OpenAPI/`) already signals the role (MistKit-side bridging of generated OpenAPI types). The `+MistKit` suffix on the older files is legacy from before that convention was established and is redundant; the user explicitly chose the terser form when offered the trade-off.

**How to apply:** When adding a new extension file for a generated `Components.*` or `Operations.*` type, use `Operations.queryRecords.Input.Path.swift`, not `Operations.queryRecords.Input.Path+MistKit.swift`. Leave existing `+MistKit`-suffixed files as-is (don't mass-rename). Also note: one extension per file — SwiftLint enforces `one_declaration_per_file` and a 225-line warning, so don't lump multiple type extensions together even when their bodies are identical.
