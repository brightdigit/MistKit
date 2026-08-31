# Handoff — Issue #407 (MistKitConfiguration)

**Worktree:** `~/Documents/Projects/MistKit/407-mistkitconfiguration`
**Branch:** `407-mistkitconfiguration`
**Status:** Parts 0–5 **done** on the draft branch. **Not merge-ready** until tags only.

## Open PRs

| Repo | PR | Base | State |
|---|---|---|---|
| MistKit | [#455](https://github.com/brightdigit/MistKit/pull/455) | `v1.0.0-beta.5` | **draft** — blocked on tagged MistKitConfiguration |
| MistKitConfiguration | [#1](https://github.com/brightdigit/MistKitConfiguration/pull/1) | `main` | **draft** — blocked on tagged ConfigKeyKit |
| ConfigKeyKit | [#8](https://github.com/brightdigit/ConfigKeyKit/pull/8) | `main` | **merged**; awaiting release tag |

## Merge gate (hard)

Neither draft merges until the published MistKitConfiguration graph is **tag-only**.
`branch:` / `revision:` / monorepo `path:` are integration-only; `dependency-policy.yml`
rejects them on PRs to `main`.

Order:

1. **You tag ConfigKeyKit** (release carrying #8)
2. MistKitConfiguration: ConfigKeyKit `branch: "main"` → `from: "<tag>"`; standalone MistKit
   dep stays `from:` → MistKitConfiguration#1 can merge
3. **You tag MistKitConfiguration**
4. Consumers that land on `main` use only `from: "<MistKitConfiguration-tag>"`
5. Then MistKit#455 can leave draft / merge; then close #407

## What landed (Parts 3–5)

- ConfigKeyKit pin in MistKitConfiguration: `revision: 90110faa…` → `branch: "main"`
  (temporary until tagged)
- **CelestraCloud** + **BushelCloud** + **MistDemo** rewired onto MistKitConfiguration
  (path dep dogfood overlay); local validators / `ConfigValueReading` / CloudKit config
  types deleted; app-specific `CloudKitConfigurationError.map` kept
- Bushel: `CloudKitConfiguration.swift` → `VirtualBuddyConfiguration.swift`;
  `BushelCloudKitService` / `SyncEngine` take `ValidatedCloudKitConfiguration`
- MistDemo: `MistDemoKeys.cloudKit = CloudKitConfigurationKeys(…)`; custom `resolveBool`
  **kept**; MistDemo `ConfigurationError` enum **kept**
- `examples.yml`: MistDemo + MistKitConfiguration lanes on `nightly-6.4.x-noble`
- `setup-mistkitconfiguration` composite action under
  `Packages/MistKitConfiguration/.github/actions/`
- DocC `ConfiguringMistKit.md` points at the MistKitConfiguration package

## Verification (last run)

```bash
(cd Packages/MistKitConfiguration && swift test)   # 35 tests
(cd Examples/CelestraCloud && swift test)         # 122 tests
(cd Examples/BushelCloud && swift test)           # 198 tests (validator suites removed)
(cd Examples/MistDemo && swift test)              # 1010 tests
```

## Hazards still in force

- Subrepo Package.swift MistKit line: monorepo `path: "../.."` vs standalone `url:` —
  re-apply after every `git subrepo push`
- Path-package identity collision: every monorepo package must reach MistKit the same way
- Do not replace MistDemo `resolveBool` with ConfigKeyKit `read` until verified post-tag

## Follow-up issues still worth filing

1. ConfigKeyKit could reject or normalize underscored key bases at build time.
2. Bushel `.env.example` documents a `CLOUDKIT_DATABASE` no Bushel code reads.
3. `PrivateKeyMaterial` isn't `Equatable` in MistKit.
4. Per-source key prefixing in ConfigKeyKit (env-only prefix).
5. MistDemo constant-drift class (Part 0 fixed one instance).
