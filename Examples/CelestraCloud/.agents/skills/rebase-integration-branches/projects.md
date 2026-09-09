# CelestraCloud config

| Key | Value |
|-----|-------|
| Container root | Parent of worktree dirs (contains `.git`, `CelestraCloud.git/`) |
| Bare store | `CelestraCloud.git` |
| `RELEASE_BRANCH` | `v1.0.0-dev.1` |
| `MAIN_BRANCH` | `main` |
| `MISTKIT_REF` | `1.0.0-beta.4` |
| `KIT_PACKAGE` | `CelestraKit` |
| `KIT_PATH` | `../CelestraKit` |
| Primary workflow | `.github/workflows/CelestraCloud.yml` |
| Feed update workflow | `.github/workflows/update-feeds.yml` |
| MistKit path (if used) | `../..` (confirm monorepo layout) |

## Expected commit counts

- `v1.0.0-dev.1` is typically 1 commit ahead of `main`
- `mistkit` / `subrepo` should be 1 commit ahead of release, 2 ahead of `main`

## Backup branches

Prefer `backup/mistkit-pre-squash` and `backup/subrepo-pre-squash`.
Legacy backups `mistkit-backup` / `subrepo-backup` may also exist.

## Differences from BushelCloud

| BushelCloud | CelestraCloud |
|-------------|---------------|
| `v1.0.0-alpha.3` | `v1.0.0-dev.1` |
| `BushelKit` | `CelestraKit` |
| `BushelCloud.yml` | `CelestraCloud.yml` |
| `bushel-cloud-build.yml` | `update-feeds.yml` |
| `cloudkit-sync/action.yml` | _(not present)_ |
| `MISTKIT_BRANCH: v1.0.0-beta.4` | `MISTKIT_BRANCH: 1.0.0-beta.4` |
