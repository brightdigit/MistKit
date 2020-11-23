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

### `request(withURL:data:)`

```swift
public func request(withURL url: URL, data: Data?) -> MKURLRequest
```
