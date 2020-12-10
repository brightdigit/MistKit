**CLASS**

# `TodoListItem`

```swift
public class TodoListItem: MKQueryRecord
```

## Properties
### `recordName`

```swift
public let recordName: UUID?
```

### `recordChangeTag`

```swift
public let recordChangeTag: String?
```

### `title`

```swift
public var title: String
```

### `completedAt`

```swift
public var completedAt: Date?
```

### `image`

```swift
public var image: MKAsset?
```

### `value`

```swift
public var value: Double?
```

### `location`

```swift
public var location: MKLocation?
```

### `fields`

```swift
public var fields: [String: MKValue]
```

## Methods
### `init(record:)`

```swift
public required init(record: MKAnyRecord) throws
```

### `init(title:recordName:recordChangeTag:)`

```swift
public init(
  title: String,
  recordName: UUID? = nil,
  recordChangeTag: String? = nil
)
```
