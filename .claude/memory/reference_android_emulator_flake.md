---
name: reference_android_emulator_flake
description: Android CI can fail after a fully successful build when the emulator never starts — adb "could not connect to TCP port 5554"; re-run, don't debug the code
metadata:
  type: reference
---

A `Build on Android (<swift>, <api>)` job can fail with **no compiler error at all**. The signature,
observed 2026-09-14 on `Build on Android (6.3, 33)` (run 34888402078):

```
[1195/1204] Compiling MistKitTests QueryFilterTests+ComplexFields.swift
[1200/1208] Emitting module MistKitPackageDiscoveredTests
[1207/1211] Emitting module MistKitPackageTests
error: could not connect to TCP port 5554: Connection refused
The process '.../platform-tools/adb' failed with exit code 1
##[error]The process '/usr/bin/sh' failed with exit code 1
```

The Swift build **completed** — every target compiled and both test modules emitted. The failure is
`skiptools/swift-android-action` failing to reach the emulator over adb, i.e. the AVD never came up.

**Why this matters:** the failing step is `Run brightdigit/swift-build@v1`, so `gh pr checks` just
says the Android job failed, and it looks like a source break. It is not. Distinguish it from a real
failure by checking for `Emitting module MistKitPackageTests` in the log — if that line is present and
there is no `error:` from swift-frontend, the code built fine.

**How to apply:** re-run the job (`gh run rerun <run-id> --job <job-id>`) rather than changing source.
Corroborating check: the other Android matrix entries (other Swift versions / API levels) pass on the
same commit — a genuine source break fails all of them, a flake fails one. Distinct from
[[reference_wasm_ci_signatures]] (wasm OOM vs SDK-download curl exit 7) and from
[[reference_windows_62_mistkittests_emit_abort]] (Windows 6.2, which fails *before* emitting
MistKitTests and is a real size tip-over).
