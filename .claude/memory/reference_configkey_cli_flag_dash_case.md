---
name: reference-configkey-cli-flag-dash-case
description: "ConfigKeyKit ConfigKey bases must use dash-case, not snake_case: CLIKeyEncoder joins components verbatim, so an underscore in a base silently produces an unusable CLI flag (ENV is unaffected)."
metadata:
  type: reference
---

A ConfigKeyKit `ConfigKey`/`OptionalConfigKey` base string must separate words
with **dashes**, not underscores: `"cloudkit.key-id"`, never `"cloudkit.key_id"`.

**Why:** the two sources normalize differently, and only one is forgiving.

| base | ENV name | CLI flag |
|---|---|---|
| `cloudkit.key-id` | `CLOUDKIT_KEY-ID` → resolves from `CLOUDKIT_KEY_ID` | `--cloudkit-key-id` ✅ |
| `cloudkit.key_id` | `CLOUDKIT_KEY_ID` ✅ | `--cloudkit-key_id` ❌ |

- swift-configuration's `EnvironmentVariablesProvider` normalizes **both** `-`
  and `.` to `_` when encoding, so either base spelling resolves the same
  `CLOUDKIT_*` variable. ENV is not a signal that the base is correct.
- `CLIKeyEncoder.encode` joins the key's components with `-` **verbatim**, so an
  underscore inside a component survives into the flag. ConfigKeyKit's
  `StandardNamingStyle.dotSeparated` returns the base unchanged, so it does not
  intervene.

**How to apply:** when adding a config key, spell the base in dash-case. Two
symptoms of getting it wrong, both silent — nothing fails at build time and ENV
keeps working:
1. The documented `--flag-name` never resolves; only the undocumented
   `--flag_name` does.
2. `CommandLineArgumentsProvider(secretsSpecifier: .specific([...]))` entries are
   matched against the *generated* flag, so a mismatch means the value is never
   marked secret — a private key passed by flag is logged unredacted.

Found in BushelCloud (fixed in #407 PR 1); CelestraCloud was already correct.
Verified empirically against swift-configuration 1.2.0, not inferred from source.

Related: [[reference-configkeykit-configvaluereading]]
