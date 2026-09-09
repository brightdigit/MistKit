---
name: project_mistdemo_no_schema_autocreate
description: The MistDemo dev container does NOT auto-create schema fields on write; unknown fields fail BAD_REQUEST "Field X not found"
metadata:
  type: project
---

The `iCloud.com.brightdigit.MistDemo` **development** container does **not** auto-create
record fields on write. Writing a field absent from `Examples/MistDemo/schema.ckdb` fails:

```
BAD_REQUEST — "Field probeFilledList not found in Note"
```

Verified 2026-09-09 (issue #481) with two live server-to-server writes to the public DB:
both an empty `.list([])` and a populated `.list([.string, .string])` were rejected the same
way, on a field name not in the schema.

**Why:** CloudKit's "development environments auto-create schema" behavior is commonly
assumed, and it is easy to read a `BAD_REQUEST` on a *new* field as evidence about the
*value* you sent. It is not — it only means the field isn't in the schema. In #481 this
nearly produced a false conclusion that CloudKit rejects empty list values.

**How to apply:** To probe wire behavior for a field type `Note` doesn't already have
(`title` STRING, `index` INT64, `image` ASSET), you must first add it to `schema.ckdb` and
push with `xcrun cktool import-schema` — which needs a CloudKit **management token**
(separate from the API/server-to-server credentials in `MistDemo.env`, and not currently
saved; `cktool export-schema` reports `No management token found`). Treat a schema push as
an outward-facing change to a shared container and confirm before running it.

Related: [[project_mistdemo_is_live_verification_oracle]] — MistDemo is the live oracle, but
only for behaviors its existing schema can actually exercise.
