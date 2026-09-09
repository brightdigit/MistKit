# FieldValue lists use Arity, not a parallel List enum (#481)

Locked domain shape (2026-09-09): each `FieldValue` kind carries `Arity<T>` (`.value` / `.list`). There is no `case list`. Empty lists are typed (e.g. `.string(.list([]))`). Deprecated scalar factories only (`string(_: String)` → `.value`); no `.list([FieldValue])` polyfill. Response OpenAPI uses `*_LIST` family, not flat `LIST`. See research `.claude/docs/research/481-homogeneous-list-without-duplicate-enums.md`.
