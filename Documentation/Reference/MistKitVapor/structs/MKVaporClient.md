**STRUCT**

# `MKVaporClient`

```swift
public struct MKVaporClient: MKHttpClient
```

## Properties
### `client`

```swift
public let client: Client
```

## Methods
### `init(client:)`

```swift
public init(client: Client)
```

### `request(withURL:data:)`

```swift
public func request(withURL url: URL, data: Data?) -> MKVaporClientRequest
```
