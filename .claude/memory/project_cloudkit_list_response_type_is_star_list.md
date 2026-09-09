---
name: project_cloudkit_list_response_type_is_star_list
description: Live CloudKit list responses use STRING_LIST (etc.), not flat LIST; empty lists round-trip as present []
metadata:
  type: project
---

Verified 2026-09-09 against `iCloud.com.brightdigit.MistDemo` / `development` /
public, S2S, on `Note.tags` (`LIST<STRING>`).

**Empty lists:** writable; create and lookup both return the field present as
`{"type":"STRING_LIST","value":[]}`. Not absent, not rejected.

**Response type tag:** CloudKit returns the granular `*_LIST` family
(`STRING_LIST`, and by implication `INT64_LIST` / `DOUBLE_LIST` / …), **not** the
flat `LIST`. Request `type` already had the `*_LIST` family. Before #481, MistKit
failed to decode any list field response with:

```
Cannot initialize _typePayload from invalid String value STRING_LIST
```

`FieldValueResponse.type` in `openapi.yaml` now matches the wire `*_LIST` family.

**Design implication for #481:** because empty `[]` still carries `STRING_LIST`,
element type is recoverable on read — no separate empty case is required for
honest decode. Also filed on issue #481.
