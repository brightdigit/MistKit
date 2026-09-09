# MistKitConfiguration subrepo carries a never-merged Package.swift overlay

`Packages/MistKitConfiguration` is a `git subrepo` of
`git@github.com:brightdigit/MistKitConfiguration.git` (branch `initial-extraction`).
Its `Package.swift` **deliberately differs between the two repos on one line**:

| Where | MistKit dependency |
|---|---|
| Monorepo (`Packages/MistKitConfiguration`) | `.package(name: "MistKit", path: "../..")` |
| Standalone repo | `.package(url: "…/MistKit.git", from: "1.0.0-beta.4")` |

Both forms are required. The `path:` form is forced by
[[project_path_package_identity_collision]] — a `path:` package's identity is the
directory name, so mixing it with a transitive `url:` MistKit fails the monorepo
build. The `url:` form is what makes a *tag* of MistKitConfiguration usable
downstream; a tag carrying `path: "../.."` resolves nowhere.

**`git subrepo push` does not know this.** It copies the subdir verbatim, so a push
from the monorepo overwrites the standalone `url:` line with `path:` and breaks the
published package. Re-apply the swap after every push. Same discipline
`Examples/BushelCloud/Package.swift:94-98` documents for its own MistKit line.

The seeding was done by hand rather than by `git subrepo push`, because the repo was
empty and GitHub cannot open a PR between unrelated histories: `main` was seeded with
a LICENSE-only initial commit first so `initial-extraction` had a merge base. As a
result `.gitrepo` records an empty `commit =`, so the *first* `git subrepo push` will
believe nothing has been pushed — check the remote before running it.
