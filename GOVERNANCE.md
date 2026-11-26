# Governance

MistKit is an open source project owned by [BrightDigit](https://brightdigit.com) and released under the [MIT License](LICENSE). It follows a maintainer-led model.

## Roles

### Maintainer

The maintainer has final say on the project's direction, merges pull requests, publishes releases, and manages repository settings and secrets.

| Name | GitHub | Responsibilities |
| --- | --- | --- |
| Leo Dion | [@leogdion](https://github.com/leogdion) | Lead maintainer, release manager, security lead |

### Contributors

Anyone who opens an issue, starts a discussion, reviews code, or submits a pull request is a contributor. Contributors don't need any special permission.

### Becoming a Maintainer

A contributor with a sustained record of high-quality contributions and reviews may be invited to become a maintainer by the existing maintainers. New maintainers are added to this file and to [`.github/CODEOWNERS`](.github/CODEOWNERS).

## Decision Making

- **Day-to-day changes** are proposed as pull requests. A pull request needs approval from a code owner and passing CI before it's merged.
- **Larger changes** (new public API, breaking changes, new dependencies, changes to the authentication or signing code) should start as a GitHub issue or discussion so the design can be agreed on before code is written.
- When there's disagreement, maintainers aim for consensus. If consensus can't be reached, the lead maintainer decides.

## Releases

- MistKit follows [Semantic Versioning](https://semver.org). During the 1.0.0 betas, breaking changes may still land between betas and are called out in the release notes.
- Work for each release happens on a `v`-prefixed branch (for example `v1.0.0-beta.6`) and is merged to `main`. Release tags are **not** `v`-prefixed (for example `1.0.0-beta.6`).
- The **Release Check** workflow verifies each tag. Publishing the GitHub release is a manual step taken by a maintainer.
- Release notes are kept in [ReleaseNotes.md](ReleaseNotes.md).

## Security

Security issues are handled privately as described in [SECURITY.md](SECURITY.md), not through public issues.

## Changes to This Document

Changes to this governance document are made by pull request and require approval from the lead maintainer.
