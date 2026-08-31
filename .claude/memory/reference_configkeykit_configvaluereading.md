---
name: reference-configkeykit-configvaluereading
description: "ConfigKeyKit#1 shipped the swift-configuration bridge as the in-core ConfigValueReading protocol (1.0.0-beta.2), NOT as a separate ConfigKeyKitConfiguration package."
metadata:
  type: reference
---

ConfigKeyKit issue #1 ("Remove Need for Extension") was resolved by putting the
`read(_:)` resolution on a protocol in the **dependency-free core**, not by
shipping the separate `ConfigKeyKitConfiguration` product its comments proposed.

- `Sources/ConfigKeyKit/ConfigValueReading.swift`, tagged `1.0.0-beta.2`.
- The core stays Foundation-only; consumers supply a ~3-line conformance:
  ```swift
  extension ConfigReader: @retroactive ConfigValueReading {
    public func makeConfigKey(_ s: String) -> Configuration.ConfigKey { .init(s) }
  }
  ```
  `Configuration` must be imported **publicly** for that conformance to compile.
- It supplies `read()` for `ConfigKey<String|Int|Double|Bool>`,
  `OptionalConfigKey<String|Int|Double|Bool|Date>`, plus `read(_:parsing:)`.
- Resolution order is `sourcePriority` (default `[.commandLine, .environment]`),
  not `ConfigKeySource.allCases`.

**There is no `ConfigKeyKitConfiguration` package** — do not look for one, and
treat any issue text that assumes it (e.g. MistKit #407's dependency diagram and
its "blocked by ConfigKeyKit#1" sequencing) as stale. The prefix-factory idea
(`ConfigKeySet(envPrefix:)`) from that thread also did not ship; `envPrefix`
remains a per-key initializer parameter.

Adopted in BushelCloud + CelestraCloud in #407 PR 1, deleting ~180 lines of
hand-rolled overloads that were character-for-character identical between them.

Related: [[reference-configkey-cli-flag-dash-case]]
