**CLASS**

# `TodoListItem`

```swift
public class TodoListItem: MKQueryRecord
```

## Properties
### `fields`

```swift
public var fields: [String: MKValue]
```

### `recordName`

```swift
public let recordName: UUID?
```

### `title`

```swift
public var title: String
```

### `recordChangeTag`

```swift
public let recordChangeTag: String?
```

## Methods
### `init(record:)`

```swift
public required init(record: MKAnyRecord) throws
```

### `init(title:recordName:recordChangeTag:)`

```swift
public init(title: String, recordName: UUID? = nil, recordChangeTag: String? = nil)
```
