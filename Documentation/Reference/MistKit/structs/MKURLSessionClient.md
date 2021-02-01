**STRUCT**

# `MKURLSessionClient`

```swift
public struct MKURLSessionClient: MKHttpClient
```

## Properties
### `session`

```swift
public let session: URLSession
```

## Methods
### `init(session:)`

```swift
public init(session: URLSession)
```

### `request(fromConfiguration:)`

```swift
public func request(
  fromConfiguration configuration: RequestConfiguration
) -> MKURLRequest
```
