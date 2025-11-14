# CKTool JS Documentation (Summary)

**Source**: https://developer.apple.com/documentation/cktooljs/
**Version**: CKTool JS 1.2.15+
**Downloaded**: November 4, 2025
**Full Documentation**: See `cktooljs-full.md` for complete Apple documentation dump

## Overview

CKTool JS gives you access to features provided in the CloudKit Console API, facilitating CloudKit setup operations for local development and integration testing. It's a JavaScript client library alternative to the macOS `cktool` command-line utility distributed with Xcode.

## Key Capabilities

With this library, you can:
- Apply a CloudKit schema file to Sandbox databases (for more information about CloudKit schema files, see "Integrating a Text-Based Schema into Your Workflow")
- Populate databases with test data
- Reset Sandbox databases to the production configuration
- Write scripts for your integration tests to incorporate

## Core Modules

The library consists of three main modules:

### 1. CKToolDatabaseModule (`@apple/cktool.database`)
This package contains all the CloudKit related types and methods, operations to fetch teams and containers for the authorized user, and utility functions and types to communicate with the CloudKit servers. This package also contains operations to work with CloudKit records. You include `@apple/cktool.database` as a dependency in your `package.json` file to access this package.

### 2. CKToolNodeJsModule (`@apple/cktool.target.nodejs`)
This package contains a `createConfiguration` function you use in projects intended to run in Node.js. You include `@apple/cktool.target.nodejs` as a dependency in your `package.json` file to access this package.

### 3. CKToolBrowserModule (`@apple/cktool.target.browser`)
This package contains a `createConfiguration` function for use in browser-based projects. You include `@apple/cktool.target.browser` as a dependency in your `package.json` file to access this package.

## API Topics

### Essentials

**Integrating CloudKit access into your JavaScript automation scripts**
- Configure your JavaScript project to use CKTool JS

### Promises API

**`PromisesApi`**
- A class that exposes promise-based functions for interacting with the API

**`CancellablePromise`**
- A promise that has a function to cancel its operation

**`CKToolDatabaseModule`**
- The imported package that provides access to CloudKit containers and databases

### Configuration

**`Configuration`**
- An object you use to hold options for communicating with the API server

**`CKToolNodeJsModule`**
- The imported package that supports using the client library within a Node.js environment

**`CKToolBrowserModule`**
- The imported package that supports using the client library within a web browser

### Global Structures and Enumerations

**`Container`**
- Details about a CloudKit container

**`ContainersResponse`**
- An object that represents results of fetching multiple CloudKit containers

**`CKEnvironment`**
- An enumeration of container environments

**`ContainersSortByField`**
- An enumeration that indicates sorting options for retrieved containers

**`SortDirection`**
- An enumeration that indicates sorting direction when applying a custom sort

### Errors

**`ErrorBase`**
- The base class of any error emitted by functions in the client library

### Classes

**`Blob`**
- Binary large object handling

**`File`**
- File handling and operations

## Installation

The library requires npm package inclusion and configuration before use in JavaScript projects.

```bash
npm install @apple/cktool.database
npm install @apple/cktool.target.nodejs  # For Node.js
# or
npm install @apple/cktool.target.browser  # For browser
```

## When to Consult This Documentation

- Setting up automated CloudKit deployment pipelines
- Creating integration test environments
- Automating schema deployment to Sandbox
- Seeding test data programmatically
- Understanding CloudKit Management API capabilities
- Building developer tooling for CloudKit workflows

## Relation to MistKit

While MistKit provides a Swift interface to CloudKit Web Services for runtime operations, CKTool JS is focused on development-time and CI/CD tooling. Understanding CKTool JS can help when:

- Building complementary tooling around MistKit
- Understanding the full CloudKit ecosystem
- Creating automated test environments for MistKit-based applications
- Implementing CI/CD pipelines that use both schema management (CKTool JS) and data operations (MistKit)

## Schema Files and Workflows

CKTool JS works with CloudKit schema files, enabling text-based schema management. This allows you to:
- Version control your CloudKit schemas
- Apply schemas programmatically during CI/CD
- Share schema definitions across teams
- Integrate schema management into automated workflows

For more information, see Apple's documentation on:
- "Integrating a Text-Based Schema into Your Workflow"
- "Automating CloudKit Development"

## Related Documentation

See also:
- `cktool.md` - Native command-line tool for CloudKit management (alternative to cktooljs)
- `webservices.md` - CloudKit Web Services REST API reference (runtime operations)
- `cloudkitjs.md` - CloudKit JS SDK for web applications (runtime operations)

## Key Differences from Other CloudKit Tools

| Tool | Purpose | Platform | Use Case |
|------|---------|----------|----------|
| **cktooljs** | Schema management | Node.js/Browser | CI/CD, automation scripts |
| **cktool** | Schema management | macOS (Xcode) | Local development, CLI |
| **CloudKit JS** | Runtime data ops | Browser | Web applications |
| **MistKit** | Runtime data ops | Swift | Swift applications |
