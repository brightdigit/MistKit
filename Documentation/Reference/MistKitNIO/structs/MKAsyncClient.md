**STRUCT**

# `MKAsyncClient`

```swift
public struct MKAsyncClient: MKHttpClient
```

## Properties
### `client`

```swift
public let client: HTTPClient
```

## Methods
### `init(client:)`

```swift
public init(client: HTTPClient)
```

### `request(withURL:data:)`

```swift
public func request(withURL url: URL, data: Data?) -> MKAsyncRequest
```
