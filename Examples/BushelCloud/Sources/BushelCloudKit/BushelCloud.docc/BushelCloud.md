# ``BushelCloud``

A CloudKit demonstration tool showcasing MistKit's Server-to-Server authentication and batch operations.

## Overview

BushelCloud is a command-line tool that demonstrates how to use MistKit to interact with CloudKit Web Services. It fetches macOS restore images, Xcode versions, and Swift compiler versions from multiple sources and syncs them to CloudKit using Server-to-Server authentication.

This is an **example application** designed for developers learning CloudKit integration patterns with Swift.

## Topics

### Getting Started

- <doc:GettingStarted>
- <doc:CloudKitSetup>

### Architecture

- <doc:DataFlow>
- <doc:CloudKitIntegration>

### Tutorials

- <doc:SyncingData>
- <doc:ExportingData>

### Core Components

- ``BushelCloudKitService``
- ``SyncEngine``
- ``DataSourcePipeline``

### Data Models

- ``RestoreImageRecord``
- ``XcodeVersionRecord``
- ``SwiftVersionRecord``
- ``DataSourceMetadata``
- ``CloudKitRecord``

### Data Sources

- ``IPSWFetcher``
- ``AppleDBFetcher``
- ``XcodeReleasesFetcher``
- ``SwiftVersionFetcher``
- ``MESUFetcher``

### Commands

- ``SyncCommand``
- ``ExportCommand``
- ``ClearCommand``
- ``ListCommand``
- ``StatusCommand``
