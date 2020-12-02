**STRUCT**

# `MKAsyncRequest`

```swift
public struct MKAsyncRequest: MKHttpRequest
```

## Properties
### `client`

```swift
public let client: HTTPClient
```

### `url`

```swift
public let url: URL
```

### `data`

```swift
public let data: Data?
```

## Methods
### `execute(_:)`

```swift
public func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void))
```
