**STRUCT**

# `ModifyRecordQuery`

```swift
public struct ModifyRecordQuery<RecordType: MKQueryRecord>: MKEncodable
```

## Properties
### `operations`

```swift
public let operations: [ModifyOperation<RecordType>]
```

### `desiredKeys`

```swift
public let desiredKeys: [String]? = nil
```

### `numbersAsStrings`

```swift
public let numbersAsStrings: Bool = true
```

## Methods
### `init(operations:)`

```swift
public init(operations: [ModifyOperation<RecordType>])
```
