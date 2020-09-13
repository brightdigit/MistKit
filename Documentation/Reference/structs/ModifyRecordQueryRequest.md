**STRUCT**

# `ModifyRecordQueryRequest`

```swift
public struct ModifyRecordQueryRequest: MKRequest
```

## Properties
### `database`

```swift
public let database: MKDatabaseType
```

### `data`

```swift
public let data: ModifyRecordQuery
```

### `subpath`

```swift
public let subpath = ["records", "modify"]
```

## Methods
### `init(database:query:)`

```swift
public init(database: MKDatabaseType, query: ModifyRecordQuery)
```
