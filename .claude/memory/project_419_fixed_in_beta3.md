---
name: project_419_fixed_in_beta3
description: Issue #419 (MistDemoApp view initializers) was already fixed in 5a58120 and verified building on macOS Swift 6.3.2
metadata:
  type: project
---

Issue **#419** ("MistDemoApp fails to build: NoteEditView/RecordDetailView have no accessible initializers") is **already resolved** — do not re-implement it.

The explicit initializers it proposes shipped in `5a58120` ("v1.0.0 beta.3", PR #408):

- `Examples/MistDemo/Sources/MistDemoApp/Views/NoteEditView.swift:150` — `internal init(mode:onSaved:)`
- `Examples/MistDemo/Sources/MistDemoApp/Views/RecordDetailView.swift:149` — `internal init(note:onChange:)`

Verified 2026-08-20 against `v1.0.0-beta.4` @ `d295c30` on Apple Swift 6.3.2 / `arm64-apple-macosx28.0` — the exact toolchain the issue reports against. `swift build --target MistDemoApp` from `Examples/MistDemo` completes cleanly (1424/1424). Evidence posted as a comment on the issue.

Only remaining noise is unrelated: `CKShare.Metadata.rootRecordID` / `rootRecord` are deprecated in macOS 13, warned at `Services/CloudKitStore+Records.swift:114`. Non-blocking; untracked as of this writing.

Underlying Swift rule worth remembering: a `@State private var` stored property drops a struct's *synthesized* memberwise init to `private`, so the view becomes unconstructible from another file. The repo's explicit-ACL policy means views should declare their inits explicitly anyway.
