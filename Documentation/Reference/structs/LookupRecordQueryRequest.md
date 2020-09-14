**STRUCT**

# `LookupRecordQueryRequest`

```swift
public struct LookupRecordQueryRequest<RecordType: MKQueryRecord>: MKRequest
```

## Properties
### `database`

```swift
public let database: MKDatabaseType
```

### `data`

```swift
public let data: LookupRecordQuery<RecordType>
```

### `subpath`

```swift
public let subpath = ["records", "lookup"]
```

## Methods
### `init(database:query:)`

```swift
public init(database: MKDatabaseType, query: LookupRecordQuery<RecordType>)
```
