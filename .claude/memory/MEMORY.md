# Memory Index

Project-scoped agent memory for MistKit. This directory **replaces** any native or global memory feature for this project (Claude Code `~/.claude/projects/<project>/memory/`, Cursor memories, knowledge stores, etc.). Do **not** save project-scoped memories there — write them here so they are versioned, reviewable, and shared across agents and teammates.

## Convention

- One markdown file per fact worth remembering: decisions, constraints, gotchas, and context that is **not** derivable from the code or git history.
- Each fact gets a one-line entry in this index (link + short summary).
- Update or delete memory files that turn out to be wrong; do not leave stale entries.
- Native/global stores may hold **exactly one** pointer memory: that project memories live in-repo at `.claude/memory/`.

## Index

- [CloudKit archived endpoints not in local docs](reference_cloudkit_archived_endpoints.md) — Verify CloudKit endpoints (e.g. assets/rereference) against Apple's archived reference, not just .claude/docs/webservices.md
- [CloudKit Zone Dictionary has exactly 3 keys](reference_cloudkit_zone_dictionary.md) — zoneID/syncToken/atomic only; isEager, modify-request `atomic`, and zone create options do NOT exist
- [wasm CI failure signatures](reference_wasm_ci_signatures.md) — Two distinct wasm failures: silent exit-1 (OOM on big test target) vs curl exit-7 (SDK download flake, just re-run)
- [Swift Testing availability guard](feedback_swift_testing_availability.md) — Never annotate @Suite types with @available; use guard #available inside @Test functions instead
- [GitHub Action pinning preference](feedback_action_pinning.md) — Use @v<major> for brightdigit-owned actions; pin third-party actions explicitly
- [CI Swift matrix preferences](feedback_ci_swift_matrix.md) — Keep Swift 6.1 in full matrix; in-dev Swift branches (6.4 snapshots) ride in the build-ubuntu matrix via an `image` override (ConfigKeyKit pattern), never a separate job
- [Test parent type — enum vs struct](feedback_test_parent_enum_vs_struct.md) — Use enum only when the type-under-test has multiple test files; otherwise simple struct
- [Explicit access modifier on every import](feedback_explicit_import_access.md) — Always write `internal import Foo` etc.; never bare `import Foo`
- [Capture follow-up findings in issues, not code](feedback_findings_to_issues_not_code.md) — When verification surfaces an out-of-scope fix, write it up on the relevant GitHub issue and stop; don't expand the current PR
- [@available semantics: deprecated vs unavailable](feedback_available_semantics.md) — Use `@available(*, unavailable)` for not-yet-ready APIs; `deprecated` is reserved for symbols that have been replaced
- [Tests and linting before commit/push](feedback_test_lint_before_commit.md) — Always run swift build + swift test + swift-format + swiftlint locally before commit/push; don't rely on CI
- [OpenAPI extension filename convention](feedback_openapi_extension_filenames.md) — New files in Extensions/OpenAPI/ use bare TypeName.swift; drop the +MistKit suffix
- [No silent policy defaults](feedback_no_silent_policy_defaults.md) — Parameters that encode meaningful policy (signing method, attribution) must be non-defaulted; prefer @available(*, deprecated) overloads to defaults
- [Sendable API fallback over @available bump](feedback_sendable_api_fallback.md) — Prefer dual-path #available + nonisolated(unsafe) cached fallback over bumping @available when cascade is wide
- [Examples/ dir is MistKit-dev dogfooding](project_examples_dir_is_for_mistkit_dev.md) — Bushel/CelestraCloud Examples test MistKit-under-development; their MISTKIT_BRANCH pin & setup-mistkit wiring aren't end-user deployment patterns
- [Check merge strategy before release deletions](feedback_check_merge_strategy_before_release_deletions.md) — Squash/rebase merge means git history alone won't preserve removed files; archive branch+tag is load-bearing, not optional
- [CI-only flake gate](feedback_ci_only_flake_gate.md) — Gate cooperative-executor flake helpers (e.g. isFlakyTimeoutSimulator) on ProcessInfo CI env AND platform, so local sim runs stay strict
- [Conditional withKnownIssue overload](feedback_conditional_known_issue_overload.md) — Prefer a `withKnownIssue(when:isIntermittent:_:)` overload over duplicating bodies in if/else around the wrap
- [setup-X action lives in repo X](feedback_setup_action_lives_in_owned_repo.md) — A `setup-<package>` composite action belongs in the package's own repo (like setup-mistkit lives in MistKit), referenced remotely by consumers
- [Skip git history on repo extraction](feedback_skip_history_on_repo_extraction.md) — When lifting code to a new subrepo, clean copy is fine; don't propose subtree split / filter-repo
- [macOS APNs entitlement key](project_macos_aps_entitlement_key.md) — macOS needs `com.apple.developer.aps-environment`; iOS uses `aps-environment`. codesign silently strips the wrong-platform key.
- [RecordResult pattern throughout API](feedback_record_result_pattern_throughout.md) — Surface per-item modify failures with the RecordResult success-or-failure pattern everywhere (subscriptions, zones…), not just records
- [Subrepo-local fixes belong in the subrepo](feedback_subrepo_fixes_belong_in_subrepo.md) — Changes isolated to an Example subrepo (e.g. CelestraCloud copyright headers) go in that subrepo's own repo, not a parent MistKit branch
- [beta.4 worktree layout](project_beta4_worktree_layout.md) — Remaining v1.0.0-beta.4 issues are developed in parallel worktrees under MistKit.git/wt-<branch>, PR'd to the v1.0.0-beta.4 base
- [#419 already fixed in beta.3](project_419_fixed_in_beta3.md) — MistDemoApp view inits shipped in 5a58120; verified building on macOS Swift 6.3.2, do not re-implement
- [Never git stash in this multi-worktree repo](feedback_never_git_stash_multiworktree.md) — The stash stack is shared across worktrees; a pop in one can bury a sibling branch's WIP. Commit instead.
