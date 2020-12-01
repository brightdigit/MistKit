**ENUM**

# `MKServerResponse`

```swift
public enum MKServerResponse<Success>: Codable where Success: Codable
```

## Cases
### `failure(_:)`

```swift
case failure(URL)
```

### `success(_:)`

```swift
case success(Success)
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

### `init(fromResult:)`

```swift
public init(fromResult result: Result<Success, Error>) throws
```

### `init(attemptRecoveryFrom:)`

```swift
public init(attemptRecoveryFrom error: Error) throws
```
