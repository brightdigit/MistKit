---
name: fix-lint
description: >-
  Triage and fix MistKit lint findings from ./Scripts/lint.sh (swift-format,
  SwiftLint, swift build, Periphery). Use when the user reports lint errors or
  warnings, asks to fix lint, or before commit/push when lint must be clean.
---

# Fix Lint

## Success criteria

`./Scripts/lint.sh` exits **0** and `summary.totalFindings == 0`. Any warning or error from any lint tool is blocking — all four tools run with `--strict`.

## Discover findings

```bash
LINT_REPORT=1 ./Scripts/lint.sh
```

`lint.sh` invokes [scripts/compile-lint-report.py](scripts/compile-lint-report.py) in report mode to produce:

- Human summary on **stderr**
- JSON between `### MISTKIT_LINT_REPORT_BEGIN ###` / `### MISTKIT_LINT_REPORT_END ###` on stdout

Read `summary.totalFindings`, `summary.failedSteps`, and each tool's `findings[]` (`file`, `line`, `rule`, `message`, `severity`).

Report mode is **read-only** (no auto-format or `swiftlint --fix`).

## Fix loop

1. Group findings by tool, then file.
2. Apply fixes (see table below).
3. Re-run `./Scripts/lint.sh` or `LINT_REPORT=1 ./Scripts/lint.sh` until clean.
4. Run targeted `swift test --filter …` for touched areas.

## Tool-specific guidance

| Tool | Typical fix |
|------|-------------|
| **swift-format** | Edit source to match rule (e.g. `for-in` over `.forEach`). Outside report mode, `lint.sh` auto-formats first. |
| **SwiftLint** | Fix the code; use `// swiftlint:disable:next <rule>` only for documented intentional exceptions. Constant URLs can use `guard let` + `preconditionFailure` instead of `!`. |
| **Periphery** | Remove dead code — do not add no-op usages to silence. |
| **swift build** | Fix compiler errors from the build step log. |

## Constraints

- Run swift-format, SwiftLint, periphery, and swift-openapi-generator through **mise** (`mise exec -- …`) when invoking outside `lint.sh`.
- Do not manually edit `Sources/MistKitOpenAPI/` — regenerate from `openapi.yaml`.
- Periphery needs a prior `swift build --build-tests` index store under `.build/`; `lint.sh` handles this ordering.

## Verify

```bash
./Scripts/lint.sh
LINT_REPORT=1 ./Scripts/lint.sh   # confirm totalFindings: 0
swift test --filter <TouchedSuite>
```
