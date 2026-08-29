---
name: Run tests and linting before commit/push
description: Always run the full test suite and lint/format scripts locally before creating a commit or pushing — never skip
type: feedback
originSessionId: 232c9c35-011f-4d68-a1a5-7bfc3cb11dd2
---
Run tests and linting/formatting scripts before committing or pushing. Don't rely on CI to catch breakage.

**Why:** User flagged this directly after observing a long refactor session. Local verification keeps PRs green from the first push and avoids embarrassing CI failures on a well-watched repo.

**How to apply:** Before any `git commit` or `git push`:
1. `swift build` from repo root (library) and from `Examples/MistDemo/` (demo).
2. `swift test` for both packages — full suite, not a filter.
3. `swift-format -i -r Sources/ Tests/ Examples/MistDemo/Sources/` and `swiftlint --fix` (or whichever formatter+linter the repo configures).
4. Re-run `swift build` after auto-fixes in case formatting changed something compilation-relevant.

If any of those fail, fix the issue before committing. Don't commit "I'll fix the lint in a follow-up" — fix it now.
