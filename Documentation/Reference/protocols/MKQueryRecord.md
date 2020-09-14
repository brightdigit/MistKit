**PROTOCOL**

# `MKQueryRecord`

```swift
public protocol MKQueryRecord
```

## Properties
### `recordName`

```swift
var recordName: UUID?
```

### `recordChangeTag`

```swift
var recordChangeTag: String?
```

### `fields`

```swift
var fields: [String: MKValue]
```

## Methods
### `init(record:)`

```swift
init(record: MKAnyRecord) throws
```
