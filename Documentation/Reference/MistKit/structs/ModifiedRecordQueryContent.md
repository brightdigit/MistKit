**STRUCT**

# `ModifiedRecordQueryContent`

```swift
public struct ModifiedRecordQueryContent<EncodedType: Codable>: Codable
```

## Properties
### `deleted`

```swift
public let deleted: [UUID]
```

### `updated`

```swift
public let updated: [EncodedType]
```

## Methods
### `init(from:)`

```swift
public init<RecordType: MKContentRecord>(
  from result: ModifiedRecordQueryResult<RecordType>
) where RecordType.ContentType == EncodedType
```
