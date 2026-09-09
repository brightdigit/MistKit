---
name: docs-live-in-docc
description: "Long-form guides, the iOSDevUK talk write-up, and the retrospectives live in the DocC catalog; the top-level docs/ tree was removed on 2026-09-08"
metadata:
  node_type: memory
  type: project
---

The top-level `docs/` directory (talk transcripts, links page, internals write-ups, retrospectives, blog drafts) was removed on 2026-09-08 on the `447-iosdevuk-talk-docc` branch. Its content was folded into:

- `Sources/MistKit/Documentation.docc/CloudKitAsYourBackend.md` — the talk, links, and Q&A (deck screenshots in `Resources/talk-*`).
- `RequestSigning.md`, `FieldTypePolymorphism.md`, `DeployingMistKit.md`, `WhatCloudKitGotWrong.md`, `WhatTheAIGotWrong.md` — new DocC articles.
- `AuthenticationAndDatabases.md` (console setup, sign-in flows, key rotation) and `HandlingErrors.md` ("Under the hood" section) — merged.
- `README.md` — "Why Server-Side CloudKit?", "Guides", and the talk link list.

The last commit that still contains `docs/` is `c7b0f3d`. No archive tag was made (Leo's decision).

**How to apply:** put new prose documentation in the DocC catalog (published on Swift Package Index via `.spi.yml`), not in a `docs/` directory. Copy code samples from current source. Verify with the symbol-graph + `docc convert` recipe: `swift build --target MistKit -Xswiftc -emit-symbol-graph -Xswiftc -emit-symbol-graph-dir -Xswiftc .build/symbol-graphs`, copy `MistKit*.symbols.json` to a scratch dir, then `docc convert Sources/MistKit/Documentation.docc --fallback-display-name MistKit --fallback-bundle-identifier com.brightdigit.MistKit --additional-symbol-graph-dir <dir> --output-path <out>` and grep for `warning:`. The transport-accepting `CloudKitService` initializers are `internal`; docs must not claim consumers can inject a `ClientTransport`.
