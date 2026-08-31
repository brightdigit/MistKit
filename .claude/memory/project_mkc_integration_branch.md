---
name: project-mkc-integration-branch
description: "MistKitConfiguration's mistkit-beta.5 branch pins the unreleased MistKit release branch; the subrepo tracks it and it must never be merged to main or tagged."
metadata:
  type: project
---

`brightdigit/MistKitConfiguration` carries two long-lived refs with different
dependency policies:

| Ref | MistKit dependency | Purpose |
|---|---|---|
| `main` | `from: "1.0.0-beta.4"` | tag-only; what `1.0.0-beta.1` was cut from |
| `mistkit-beta.5` | `branch: "v1.0.0-beta.5"` | integration; tracks unreleased MistKit |

`Packages/MistKitConfiguration/.gitrepo` tracks **`mistkit-beta.5`** (created
2026-08-31 at `a70afee`), not `main` and no longer `initial-extraction` — that
branch was squash-merged as `6df3ad4`, so its commits are not on `main` and a
subrepo pull against it would diff against history that no longer exists.

**`mistkit-beta.5` must never be merged to `main` or tagged.** A `branch:`
requirement in a published tag is unresolvable for downstream consumers;
`dependency-policy.yml` rejects branch/revision/path requirements on non-draft PRs
to `main`, which is the guard. The branch exists so MistKitConfiguration can be
exercised against MistKit features that have not shipped (#444's `ZoneType` /
`ZoneInfo.deleted`).

**`Packages/MistKitConfiguration` is scaffolding for the beta.5 line and must be
removed before `main`.** It rides the `v1.0.0-beta.5` release branch so MistKit and
MistKitConfiguration can be developed together, but it is deliberately **not** part of
the shipped MistKit repo: the release PR `v1.0.0-beta.5` → `main` deletes the subrepo,
and anything still needing the package consumes it as a normal tagged dependency.

Leaving it in would be circular — a MistKit release carrying a package whose `.gitrepo`
tracks a branch pinning that same unreleased release.

**Retirement order:** merge feature PRs into `v1.0.0-beta.5` with the subrepo intact →
before the `→ main` release PR, delete `Packages/MistKitConfiguration` and drop its
`examples.yml` lane → tag MistKit `1.0.0-beta.5` → bump MistKitConfiguration `main` to
`from: "1.0.0-beta.5"`, cut `1.0.0-beta.2`, delete the `mistkit-beta.5` branch.

Note this is the *standalone* repo's wiring. It does not change how the monorepo
builds: `Examples/` and `Packages/` still reach MistKit by `path: "../.."` — see
[[project_dogfood_pins_are_branch_pins_not_tags]].

Related: [[project_mistkitconfiguration_subrepo_overlay]],
[[project_path_package_identity_collision]]
