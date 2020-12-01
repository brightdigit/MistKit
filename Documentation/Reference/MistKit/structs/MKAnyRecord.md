**STRUCT**

# `MKAnyRecord`

```swift
public struct MKAnyRecord: Codable
```

## Properties
### `recordType`

```swift
public let recordType: String
```

### `recordName`

```swift
public let recordName: UUID?
```

### `recordChangeTag`

```swift
public let recordChangeTag: String?
```

### `fields`

```swift
public let fields: [String: MKValue]
```

## Methods
### `init(record:)`

```swift
public init<RecordType: MKQueryRecord>(record: RecordType)
```
