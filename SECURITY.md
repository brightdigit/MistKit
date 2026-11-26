# Security Policy

MistKit handles credentials that grant access to CloudKit data: server-to-server ECDSA P-256 private keys, API tokens, and web auth tokens. A web auth token opens a user's **private** iCloud database, so we treat vulnerabilities in signing, token handling, and logging as high priority.

## Supported Versions

MistKit is in pre-1.0 betas. Security fixes go into the latest beta release and the `main` branch only. Once 1.0.0 ships, the latest minor release of the current major version will receive fixes.

| Version | Supported |
| --- | --- |
| Latest `1.0.0-beta.x` | ✅ |
| Older betas and alphas | ❌ (upgrade to the latest beta) |
| `0.x` | ❌ |

## Reporting a Vulnerability

**Please don't open a public issue, discussion, or pull request for a security problem.**

Report it privately through GitHub's [private vulnerability reporting](https://github.com/brightdigit/MistKit/security/advisories/new) (the **Report a vulnerability** button on the repository's **Security** tab).

Please include:

- The MistKit version or commit, Swift version, and platform
- Which authentication method is involved (API token, web auth token, or server-to-server)
- Steps to reproduce, or a proof of concept
- The impact as you understand it

**Never include real CloudKit keys, tokens, or container data in a report.** Use placeholder or revoked credentials.

## What to Expect

- **Acknowledgement** within 3 business days.
- **Initial assessment** within 10 business days, including whether we accept the report and a rough severity.
- **Fix and disclosure:** we'll work on a fix in a private fork, agree on a disclosure date with you, and publish a GitHub Security Advisory (with a CVE where appropriate) alongside the patched release. We aim to ship fixes for critical issues within 30 days.
- **Credit:** we'll credit you in the advisory unless you'd rather stay anonymous.

## Scope

In scope:

- Request signing for server-to-server authentication
- Handling, storage, and redaction of API tokens, web auth tokens, and private keys
- Credentials or sensitive record data leaking into logs, errors, or descriptions
- Decoding of untrusted responses from CloudKit Web Services
- The `MistDemo` example and the scripts and GitHub Actions workflows in this repository

Out of scope:

- Vulnerabilities in CloudKit or Apple's servers themselves. Report those to [Apple Product Security](https://security.apple.com).
- Vulnerabilities in third-party dependencies with no MistKit-specific impact. Report those upstream, though we're happy to hear about them so we can update.
- Credentials an application leaks through its own code or configuration.

## Security Contact

Security lead: [Leo Dion](https://github.com/leogdion) (@leogdion). See [GOVERNANCE.md](GOVERNANCE.md) for project roles.
