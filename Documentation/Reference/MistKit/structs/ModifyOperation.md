**STRUCT**

# `ModifyOperation`

```swift
public struct ModifyOperation<RecordType: MKQueryRecord>: Encodable
```

## Properties
### `operationType`

```swift
public let operationType: ModifyOperationType
```

### `record`

```swift
public let record: MKAnyRecord
```

### `desiredKeys`

```swift
public let desiredKeys: [String]?
```

## Methods
### `init(operationType:record:desiredKeys:)`

```swift
public init(operationType: ModifyOperationType, record: RecordType, desiredKeys: [String]? = nil)
```
