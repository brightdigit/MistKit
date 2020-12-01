**STRUCT**

# `FetchRecordQueryRequest`

```swift
public struct FetchRecordQueryRequest<QueryType: MKQueryProtocol>: MKRequest
```

## Properties
### `database`

```swift
public let database: MKDatabaseType
```

### `data`

```swift
public let data: FetchRecordQuery<QueryType>
```

### `subpath`

```swift
public let subpath = ["records", "query"]
```

## Methods
### `init(database:query:)`

```swift
public init(database: MKDatabaseType, query: FetchRecordQuery<QueryType>)
```
