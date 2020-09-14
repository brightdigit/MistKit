
<p align="center">
    <img alt="MistKit" title="MistKit" src="Assets/logo.svg" height="200">
</p>
<h1 align="center"> MistKit </h1>

Swift package for accessing CloudKit for server-side or command-line Swift development.

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Twitter](https://img.shields.io/badge/twitter-@brightdigit-blue.svg?style=flat)](http://twitter.com/brightdigit)
![GitHub](https://img.shields.io/github/license/brightdigit/MistKit)
![GitHub issues](https://img.shields.io/github/issues/brightdigit/MistKit)

[![macOS](https://github.com/brightdigit/MistKit/workflows/macOS/badge.svg)](https://github.com/brightdigit/MistKit/actions?query=workflow%3AmacOS)
[![ubuntu](https://github.com/brightdigit/MistKit/workflows/ubuntu/badge.svg)](https://github.com/brightdigit/MistKit/actions?query=workflow%3Aubuntu)
[![Travis (.com)](https://img.shields.io/travis/com/brightdigit/MistKit?logo=travis)](https://travis-ci.com/brightdigit/MistKit)
[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/MistKit)](https://codecov.io/gh/brightdigit/MistKit)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/MistKit)](https://www.codefactor.io/repository/github/brightdigit/MistKit)
[![codebeat badge](https://codebeat.co/badges/c47b7e58-867c-410b-80c5-57e10140ba0f)](https://codebeat.co/projects/github-com-brightdigit-mistkit-main)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/brightdigit/MistKit)](https://codeclimate.com/github/brightdigit/MistKit)
[![Code Climate technical debt](https://img.shields.io/codeclimate/tech-debt/brightdigit/MistKit?label=debt)](https://codeclimate.com/github/brightdigit/MistKit)
[![Code Climate issues](https://img.shields.io/codeclimate/issues/brightdigit/MistKit)](https://codeclimate.com/github/brightdigit/MistKit)

[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

# Introduction

Access CloudKit outside of the CloudKit framework via Web Services. Why?

* Building a Command Line Application
* Required for Server-Side Integration (via Vapor)
* Access via AWS Lambda 
* Migrating Data from/to CloudKit

... and more

```swift
// Example for pulling a todo list from CloudKit
import MistKit
import MistKitNIOHTTP1Token

// setup your connection to CloudKit
let connection = MKDatabaseConnection(
  container: "iCloud.com.brightdigit.MistDemo", 
  apiToken: "****", 
  environment: .development
)

// setup how to manager your user's web authentication token 
let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())

// setup your database manager
let database = MKDatabase(
  connection: connection,
  tokenManager: manager
)

// create your request to CloudKit
let query = MKQuery(recordType: TodoListItem.self)

let request = FetchRecordQueryRequest(
  database: .private, 
  query: FetchRecordQuery(query: query))

// handle the result
database.query(request) { result in
  dump(result)
}
```

# Features 

Here's what's currently implemented with this library:

- [x] Composing Web Service Requests
- [x] Modifying Records (records/modify)
- [x] Fetching Records Using a Query (records/query)
- [x] Fetching Records by Record Name (records/lookup)
- [x] Fetching Current User (users/current)

# Requirements 

_Coming Soon_

# Installation

```swift    
let package = Package(
  ...
  dependencies: [
      // Dependencies declare other packages that this package depends on.
      // .package(url: /* package url */, from: "1.0.0"),
    .package(url: "https://github.com/brightdigit/MistKit", .branch("main")
  ],
  targets: [
      // Targets are the basic building blocks of a package. A target can define a module or a test suite.
      // Targets can depend on other targets in this package, and on products in packages this package depends on.
      .target(
          name: "YourTarget",
          dependencies: ["MistKit","MistKitNIOHTTP1Token", ...]),
      ...
  ]
)
```

# Usage 

## Composing Web Service Requests

_Coming Soon_

```swift
let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

// setup your database manager
let database = MKDatabase(
  connection: connection,
  tokenManager: manager
)
```

### Setting Up Authenticated Requests

```swift
let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

// setup how to manager your user's web authentication token
let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())

// setup your database manager
let database = MKDatabase(
  connection: connection,
  tokenManager: manager
)
```

_Coming Soon_

## Fetching Records Using a Query (records/query)

### Setting Up Queries

```swift
// create your request to CloudKit
let query = MKAnyQuery(recordType: TodoListItem.recordType)

let request = FetchRecordQueryRequest(
  database: .private,
  query: FetchRecordQuery(query: query)
)

// handle the result
database.perform(request: request) { result in
  do {
    try print(result.get().records.information)
  } catch {
    completed(error)
    return
  }
  completed(nil)
}
```

_Coming Soon_

### Strong-Typed Queries

```swift
// create your request to CloudKit
let query = MKQuery(recordType: TodoListItem.self)

let request = FetchRecordQueryRequest(
  database: .private,
  query: FetchRecordQuery(query: query)
)

// handle the result
database.query(request) { result in
  do {
    try print(result.get().information)
  } catch {
    completed(error)
    return
  }
  completed(nil)
}
```

_Coming Soon_

### Filters 

_Coming Soon_

## Fetching Records by Record Name (records/lookup)

```swift
let recordNames : [UUID] = [...]

let query = LookupRecordQuery(TodoListItem.self, recordNames: recordNames)

let request = LookupRecordQueryRequest(database: .private, query: query)

database.lookup(request) { result in
  try? print(result.get().count)
}
```

_Coming Soon_

## Fetching Current User Identity (users/caller)

```swift
let request = GetCurrentUserIdentityRequest()
database.perform(request: request) { (result) in
  try? print(result.get().userRecordName)
}
```

_Coming Soon_

## Modifying Records (records/modify)

### Creating Records

```swift
let item = TodoListItem(title: title)

let operation = ModifyOperation(operationType: .create, record: item)

let query = ModifyRecordQuery(operations: [operation])

let request = ModifyRecordQueryRequest(database: .private, query: query)

database.perform(operations: request) { result in
  do {
    try print(result.get().updated.information)
  } catch {
    completed(error)
    return
  }
  completed(nil)
}
```

### Deleting Records

```swift
let query = LookupRecordQuery(TodoListItem.self, recordNames: recordNames)

let request = LookupRecordQueryRequest(database: .private, query: query)

database.lookup(request) { result in
  let items: [TodoListItem]
  
  do {
    items = try result.get()
  } catch {
    completed(error)
    return
  }
  
  let operations = items.map {
    ModifyOperation(operationType: .delete, record: $0)
  }

  let query = ModifyRecordQuery(operations: operations)

  let request = ModifyRecordQueryRequest(database: .private, query: query)
  
  database.perform(operations: request) { result in
    do {
      try print("Deleted \(result.get().deleted.count) items.")
    } catch {
      completed(error)
      return
    }
    completed(nil)
  }
}
```

### Updating Records

```swift
let query = LookupRecordQuery(TodoListItem.self, recordNames: [recordName])

let request = LookupRecordQueryRequest(database: .private, query: query)

database.lookup(request) { result in
  let items: [TodoListItem]
  do {
    items = try result.get()

  } catch {
    completed(error)
    return
  }
  let operations = items.map { (item) -> ModifyOperation<TodoListItem> in
    item.title = self.newTitle
    return ModifyOperation(operationType: .update, record: item)
  }

  let query = ModifyRecordQuery(operations: operations)

  let request = ModifyRecordQueryRequest(database: .private, query: query)
  database.perform(operations: request) { result in
    do {
      try print("Updated \(result.get().updated.count) items.")
    } catch {
      completed(error)
      return
    }
    completed(nil)
  }
}
```

## Further Code Documentation

[Documentation Here](/docs/README.md)

# Roadmap

<!-- https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html#//apple_ref/doc/uid/TP40015240-CH41-SW1 -->

## 0.1.0

- [x] Composing Web Service Requests
- [x] Modifying Records (records/modify)
- [x] Fetching Records Using a Query (records/query)
- [x] Fetching Records by Record Name (records/lookup)
- [x] Fetching Current User Identity (users/caller)

## 0.2.0 

- [ ] Vapor Token Client
- [ ] Vapor URL Client
- [ ] Swift NIO URL Client

## 0.4.0 

- [ ] Date Field Types
- [ ] Location Field Types
- [ ] List Field Types

## 0.6.0

- [ ] Name Component Types
- [ ] Discovering User Identities (POST users/discover)
- [ ] Discovering All User Identities (GET users/discover)

## 0.8.0

- [ ] Uploading Assets (assets/upload)
- [ ] Referencing Existing Assets (assets/rereference)
- [ ] Fetching Records Using a Query (records/query) w/ basic filtering

## 0.9.0

- [ ] Fetching Contacts (users/lookup/contacts)
- [ ] Fetching Users by Email (users/lookup/email)
- [ ] Fetching Users by Record Name (users/lookup/id)

## v1.0.0

- [ ] Reference Field Types
- [ ] Error Codes
- [ ] Handle Data Size Limits

## v1.x.x+

- [ ] Fetching Record Changes (records/changes)
- [ ] Fetching Record Information (records/resolve)
- [ ] Accepting Share Records (records/accept)
- [ ] Fetching Zones (zones/list)
- [ ] Fetching Zones by Identifier (zones/lookup)
- [ ] Modifying Zones (zones/modify)
- [ ] Fetching Database Changes (changes/database)
- [ ] Fetching Record Zone Changes (changes/zone)
- [ ] Fetching Zone Changes (zones/changes)
- [ ] Fetching Subscriptions (subscriptions/list)
- [ ] Fetching Subscriptions by Identifier (subscriptions/lookup)
- [ ] Modifying Subscriptions (subscriptions/modify)
- [ ] Creating APNs Tokens (tokens/create)
- [ ] Registering Tokens (tokens/register)

<!-- Explain Demo Application -->

## Not Planned

- [ ] Fetching Current User (users/current) _deprecated_

# License 

This code is distributed under the MIT license. See the [LICENSE](LICENSE.md) file for more info.
