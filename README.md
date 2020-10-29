
<p align="center">
    <img alt="MistKit" title="MistKit" src="Assets/logo.svg" height="200">
</p>
<h1 align="center"> MistKit </h1>

Swift Package for Server-Side and Command-Line Access to CloudKit Web Services

[![SwiftPM](https://img.shields.io/badge/SPM-Linux%20%7C%20iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-success?logo=swift)](https://swift.org)
[![Twitter](https://img.shields.io/badge/twitter-@brightdigit-blue.svg?style=flat)](http://twitter.com/brightdigit)
![GitHub](https://img.shields.io/github/license/brightdigit/MistKit)
![GitHub issues](https://img.shields.io/github/issues/brightdigit/MistKit)

[![macOS](https://github.com/brightdigit/MistKit/workflows/macOS/badge.svg)](https://github.com/brightdigit/MistKit/actions?query=workflow%3AmacOS)
[![ubuntu](https://github.com/brightdigit/MistKit/workflows/ubuntu/badge.svg)](https://github.com/brightdigit/MistKit/actions?query=workflow%3Aubuntu)
[![Travis (.com)](https://img.shields.io/travis/com/brightdigit/MistKit?logo=travis&?label=travis-ci)](https://travis-ci.com/brightdigit/MistKit)
[![Bitrise](https://img.shields.io/bitrise/b2595eab70c25d1b?logo=bitrise&?label=bitrise&token=rHUhEUFkU2RUL-KGmrKX1Q)](https://app.bitrise.io/app/b2595eab70c25d1b)
[![CircleCI](https://img.shields.io/circleci/build/github/brightdigit/MistKit?logo=circleci&?label=circle-ci&token=45c9ff6a86f9ac6c1ec8c85c3bc02f4d8859aa6b)](https://app.circleci.com/pipelines/github/brightdigit/MistKit)

[![Codecov](https://img.shields.io/codecov/c/github/brightdigit/MistKit)](https://codecov.io/gh/brightdigit/MistKit)
[![CodeFactor Grade](https://img.shields.io/codefactor/grade/github/brightdigit/MistKit)](https://www.codefactor.io/repository/github/brightdigit/MistKit)
[![codebeat badge](https://codebeat.co/badges/c47b7e58-867c-410b-80c5-57e10140ba0f)](https://codebeat.co/projects/github-com-brightdigit-mistkit-main)
[![Code Climate maintainability](https://img.shields.io/codeclimate/maintainability/brightdigit/MistKit)](https://codeclimate.com/github/brightdigit/MistKit)
[![Code Climate technical debt](https://img.shields.io/codeclimate/tech-debt/brightdigit/MistKit?label=debt)](https://codeclimate.com/github/brightdigit/MistKit)
[![Code Climate issues](https://img.shields.io/codeclimate/issues/brightdigit/MistKit)](https://codeclimate.com/github/brightdigit/MistKit)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)

![Demonstration of MistKit via Command-Line App `mistdemoc`](Assets/MistKitDemo.gif)


# Table of Contents

   * [**Introduction**](#introduction)
   * [**Features**](#features)
   * [**Installation**](#installation)
   * [**Usage**](#usage)
      * [Composing Web Service Requests](#composing-web-service-requests)
      * [Fetching Records Using a Query (records/query)](#fetching-records-using-a-query-recordsquery)
      * [Fetching Records by Record Name (records/lookup)](#fetching-records-by-record-name-recordslookup)
      * [Fetching Current User Identity (users/caller)](#fetching-current-user-identity-userscaller)
      * [Modifying Records (records/modify)](#modifying-records-recordsmodify)
      * [Examples](#examples)
      * [Further Code Documentation](#further-code-documentation)
   * [**Roadmap**](#roadmap)
      * [~~0.1.0~~](#010)
      * [**0.2.0**](#020)
      * [0.4.0](#040)
      * [0.6.0](#060)
      * [0.8.0](#080)
      * [0.9.0](#090)
      * [v1.0.0](#v100)
   * [**License**](#license)

# Introduction

Rather than the CloudKit framework this Swift package uses [CloudKit Web Services.](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/index.html#//apple_ref/doc/uid/TP40015240-CH41-SW1). Why?

* Building a **Command Line Application**
* Use on **Linux** (or any other non-Apple OS)
* Required for **Server-Side Integration (via Vapor)**
* Access via **AWS Lambda**
* **Migrating Data from/to CloudKit**

... and more

In my case, I was using this for **the Vapor back-end for my Apple Watch app [Heartwitch](https://heartwitch.app)**. Here's some example code showing how to setup and use **MistKit** with CloudKit container.

### Demo Example

#### CloudKit Dashboard Schema

![Sample Schema for Todo List](Assets/CloudKitDB-Demo-Schema.jpg)

#### Sample Code using **MistKit**

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
- [x] Fetching Current User Identity (users/caller)

# Installation

Swift Package Manager is Apple's decentralized dependency manager to integrate libraries to your Swift projects. It is now fully integrated with Xcode 11.

To integrate **MistKit** into your project using SPM, specify it in your Package.swift file:

```swift    
let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit", .branch("main")
  ],
  targets: [
      .target(
          name: "YourTarget",
          dependencies: ["MistKit", ...]),
      ...
  ]
)
```

# Usage 

## Composing Web Service Requests

**MistKit** requires a connection be setup with the following properties:

* `container` name in the format of `iCloud.com.*.*` such as `iCloud.com.brightdigit.MistDemo`
* `apiToken` which can be [created through the CloudKit Dashboard](https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/SettingUpWebServices.html#//apple_ref/doc/uid/TP40015240-CH24-SW1)
* `environment` which can be either `development` or `production`

Here's an example of how to setup an `MKDatabase`:

```swift
let connection = MKDatabaseConnection(
  container: options.container, 
  apiToken: options.apiKey, 
  environment: options.environment)

// setup your database manager
let database = MKDatabase(
  connection: connection,
  tokenManager: manager
)
```

Before getting into make an actual request, you should probably know how to make authenticated request for `private` or `shared` databases.

### Setting Up Authenticated Requests

In order to have access to `private` or `shared` databases, the Cloud Web Services API require a web authentication token. In order for the MistKit to obtain this, an http server is setup to listen to the callback from CloudKit.

Therefore when you setup your API token, make sure to setup a url for the Sign-In Callback:

![CloudKit Dashboard](Assets/CloudKitDB-APIToken.png)

Once that's setup, you can setup a `MKTokenManager`.

![CloudKit Dashboard Callback](Assets/CloudKitDB-APIToken-Callback.png)

#### Managing Web Authentication Tokens

`MKTokenManager` requires two components:

* `MKTokenStorage` stores the token for later
  * `MKFileStorage` stores the token as a simple text file
  * `MKUserDefaultsStorage` stores the token using `UserDefaults`
* `MKTokenClient` sets up an http server for listening for the web authentication token
  * `MKNIOHTTP1TokenClient` sets up an http server using SwiftNIO

```swift
let connection = MKDatabaseConnection(
  container: options.container, 
  apiToken: options.apiKey, 
  environment: options.environment
 )

// setup how to manager your user's web authentication token
let manager = MKTokenManager(
  // store the token in UserDefaults
  storage: MKUserDefaultsStorage(), 
  // setup an http server at localhost for port 7000
  client: MKNIOHTTP1TokenClient(bindTo: .ipAddress(host: "127.0.0.1", port: 7000))
)

// setup your database manager
let database = MKDatabase(
  connection: connection,
  tokenManager: manager
)
```

If you already have access to the `webAuthenticationToken`, you can set the token in the `MKTokenManager` at any point in your application:

```swift
// setup how to manager your user's web authentication token
let manager = MKTokenManager(
  // store the token in UserDefaults
  storage: MKUserDefaultsStorage(), 
  // setup an http server at localhost for port 7000
  client: MKNIOHTTP1TokenClient(bindTo: .ipAddress(host: "127.0.0.1", port: 7000))

// use the webAuthenticationToken which is passed
if let token = options.token {
  manager.webAuthenticationToken = token
}
...
```

A great example of this is if you are already, logged in an iPhone app using CloudKit and wish to [save the webAuthenticationToken from `CKFetchWebAuthTokenOperation` into a database using server-side swift](https://developer.apple.com/documentation/cloudkit/ckfetchwebauthtokenoperation).

##### Using `MKNIOHTTP1TokenClient`

To use `MKNIOHTTP1TokenClient`, add `MistKitNIOHTTP1Token` to your package dependency:

```swift
let package = Package(
  ...
  dependencies: [
    .package(url: "https://github.com/brightdigit/MistKit", .branch("main")
  ],
  targets: [
      .target(
          name: "YourTarget",
          dependencies: ["MistKit", "MistKitNIOHTTP1Token", ...]),
      ...
  ]
)
```

When a request fails due to authentication failure, `MKNIOHTTP1TokenClient` will start an http server to begin listening to web authentication token. By default, `MKNIOHTTP1TokenClient` will simply print the url but you can override the `onRequestURL`:

```swift
public class MKNIOHTTP1TokenClient: MKTokenClient {
  
  public init(bindTo: BindTo, onRedirectURL : ((URL) -> Void)? = nil) {
    self.bindTo = bindTo
    self.onRedirectURL = onRedirectURL ?? {print($0)}
  }
  ...
}
```

## Fetching Records Using a Query (records/query)

There are two ways to fetch records:

* using an `MKAnyQuery` to fetch `MKAnyRecord` items
* using a custom type which implements `MKQueryRecord`

### Setting Up Queries

To fetch as `MKAnyRecord`, simply create `MKAnyQuery` with the matching `recordType` (i.e. schema name). 

```swift
// create your request to CloudKit
let query = MKAnyQuery(recordType: "TodoListItem")

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

This will give you `MKAnyRecord` items which contain a `fields` property with your values:

```swift
public struct MKAnyRecord: Codable {
  public let recordType: String
  public let recordName: UUID?
  public let recordChangeTag: String?
  public let fields: [String: MKValue]
  ...
```

The `MKValue` type is an enum which contains the type and value of the field.

### Strong-Typed Queries

In order to use a custom type for requests, you need to implement `MKQueryRecord`. Here's an example of a todo item which contains a title property:

```swift
public class TodoListItem: MKQueryRecord {
  // required property and methods for MKQueryRecord
  public static var recordType: String = "TodoItem"
  public static var desiredKeys: [String]? = ["title"]

  public let recordName: UUID?
  public let recordChangeTag: String?
  
  public required init(record: MKAnyRecord) throws {
    recordName = record.recordName
    recordChangeTag = record.recordChangeTag
    title = try record.string(fromKey: "title")
  }
  
  public var fields: [String: MKValue] {
    return ["title": .string(title)]
  }
  
  // custom fields and methods to `TodoListItem`
  public var title: String
  
  public init(title: String) {
    self.title = title
    recordName = nil
    recordChangeTag = nil
  }
}
```

Now you can create an `MKQuery` using your custom type.

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

Rather than using `MKDatabase.perform(request:)`, use `MKDatabase.query(_ query:)` and `MKDatabase` will decode the value to your custom type.

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

In order to delete and update records, you are required to already have the object fetched from CloudKit. Therefore you'll need to run a `LookupRecordQueryRequest` or `FetchRecordQueryRequest` to get access to the record. Once you have access to the records, simply create a delete operation with your record:

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
  
  let operations = items.map { (item) in
    ModifyOperation(operationType: .delete, record: item)
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

Similarly with updating records, you are required to already have the object fetched from CloudKit. Again, run a `LookupRecordQueryRequest` or `FetchRecordQueryRequest` to get access to the record. Once you have access to the records, simply create a update operation with your record:

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

## Examples

For now checkout [the `mistdemoc` Swift package executable here](https://github.com/brightdigit/MistKit/tree/main/Sources/mistdemoc) on how to do basic CRUD methods in CloudKit via MistKit.

## Further Code Documentation

[Documentation Here](/Documentation/Reference/README.md)

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
- [ ] Vapor Token Storage
- [ ] Vapor URL Client
- [ ] Swift NIO URL Client

## 0.4.0 

- [ ] Date Field Types
- [ ] Location Field Types
- [ ] List Field Types
- [ ] System Field Integration

## 0.6.0

- [ ] Name Component Types
- [ ] Discovering User Identities (POST users/discover)
- [ ] Discovering All User Identities (GET users/discover)
- [ ] Support `postMessage` for Authentication Requests

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

This code is distributed under the MIT license. See the [LICENSE](LICENSE) file for more info.
