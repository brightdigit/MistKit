**STRUCT**

# `LookupRecordQuery`

```swift
public struct LookupRecordQuery<RecordType: MKQueryRecord>: MKEncodable
```

## Properties
### `records`

```swift
public let records: [LookupRecord]
```

### `desiredKeys`

```swift
public let desiredKeys: [String]?
```

### `numbersAsStrings`

```swift
public let numbersAsStrings: Bool = true
```

## Methods
### `init(_:recordNames:)`

```swift
public init(_: RecordType.Type, recordNames: [UUID])
```
