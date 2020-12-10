**ENUM**

# `MKValue`

```swift
public enum MKValue: Codable, Equatable
```

## Cases
### `string(_:)`

```swift
case string(String)
```

### `integer(_:)`

```swift
case integer(Int64)
```

### `data(_:)`

```swift
case data(Data)
```

### `date(_:)`

```swift
case date(Date)
```

### `double(_:)`

```swift
case double(Double)
```

### `location(_:)`

```swift
case location(MKLocation)
```

### `asset(_:)`

```swift
case asset(MKAsset)
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

### `encode(to:)`

```swift
public func encode(to encoder: Encoder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| encoder | The encoder to write data to. |