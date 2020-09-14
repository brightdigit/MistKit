**ENUM**

# `ModifiedRecord`

```swift
public enum ModifiedRecord: Decodable
```

## Cases
### `deleted(_:)`

```swift
case deleted(UUID)
```

### `updated(_:)`

```swift
case updated(MKAnyRecord)
```

## Methods
### `init(from:)`

```swift
public init(from decoder: Decoder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| decoder | The decoder to read data from. |