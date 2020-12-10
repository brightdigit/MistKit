**STRUCT**

# `MKVaporClientRequest`

```swift
public struct MKVaporClientRequest: MKHttpRequest
```

## Properties
### `client`

```swift
public let client: Client
```

### `request`

```swift
public let request: ClientRequest
```

## Methods
### `execute(_:)`

```swift
public func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void))
```
