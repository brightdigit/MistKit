# Getting Started with BushelCloud

Learn how to build, configure, and run BushelCloud.

## Overview

BushelCloud is a command-line demonstration tool that shows how to use MistKit to interact with CloudKit Web Services. This guide will help you get started with building and running the tool.

## Prerequisites

- Swift 6.1 or later
- macOS 14.0+ (for CloudKit functionality)
- A CloudKit container with Server-to-Server authentication configured
- Mint (for development tools): `brew install mint`

## Building the Project

Build BushelCloud using Swift Package Manager:

```bash
swift build
```

Or use the provided Makefile:

```bash
make build
```

The executable will be available at `.build/debug/bushel-cloud`.

## Quick Test

Run a dry-run sync to test without uploading to CloudKit:

```bash
.build/debug/bushel-cloud sync --dry-run --verbose
```

This fetches data from external sources without uploading to CloudKit, and shows verbose output explaining what's happening.

## Next Steps

- <doc:CloudKitSetup> - Configure CloudKit Server-to-Server authentication
- <doc:SyncingData> - Learn how to sync data to CloudKit
- <doc:ExportingData> - Export CloudKit data to JSON

## Development

For development with linting and testing:

```bash
make test     # Run tests
make lint     # Run linting
make xcode    # Generate Xcode project
```

Use Dev Containers for Linux development:

```bash
make docker-test    # Test in Docker
```

See the README for complete development instructions.
