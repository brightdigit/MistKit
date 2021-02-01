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

### `request(fromConfiguration:)`

```swift
public func request(
  fromConfiguration configuration: RequestConfiguration
) -> MKAsyncRequest
```
