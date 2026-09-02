# Path-package identity is the directory name, not `name:`

A local `.package(name: "MistKit", path: "../..")` gets its **package identity from the
resolved directory's basename** — in a worktree that is the worktree folder name (e.g.
`407-mistkitconfiguration`), **not** `mistkit` and not the `name:` argument.

Consequence: if any package in the graph also depends on MistKit by **URL**
(`https://github.com/brightdigit/MistKit.git`, identity `mistkit`), SPM sees two distinct
packages, resolves **both**, and the build fails:

```
error: multiple similar targets 'MistKit', 'MistKitOpenAPI' appear in package
'mistkit' and '407-mistkitconfiguration', this may indicate that the two packages
are the same and can be de-duplicated by using mirrors.
```

`swift package resolve` **succeeds** — the failure only appears at `swift build`, so a
green resolve is not evidence the graph is sound.

**Apply:** every package inside this monorepo that needs MistKit must use the *same*
`path:` dependency as its siblings. Never mix a `path:` MistKit with a transitive `url:`
MistKit. This is why `Packages/MistKitConfiguration` uses `.package(name: "MistKit",
path: "../..")` rather than a tagged URL, and why its `path:` line is a monorepo-local
overlay that must be swapped for a `url:` before the standalone repo is tagged — the same
never-merged-overlay discipline documented at `Examples/BushelCloud/Package.swift:94-98`.

Verified empirically 2026-08-31 with a two-package scratch fixture: URL-form fails at
build; both-path form builds clean. See [[project_examples_dir_is_for_mistkit_dev]] and
[[project_mistkit_branch_pin_resolves_tags]].
