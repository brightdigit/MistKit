**CLASS**

# `MKStaticTokenManager`

```swift
public class MKStaticTokenManager: MKTokenManagerProtocol
```

## Properties
### `token`

```swift
public let token: String?
```

### `client`

```swift
public let client: MKTokenClient?
```

### `webAuthenticationToken`

```swift
public var webAuthenticationToken: String?
```

## Methods
### `init(token:client:)`

```swift
public init(token: String?, client: MKTokenClient?)
```

### `request(_:_:)`

```swift
public func request(
  _ request: MKAuthenticationRedirect,
  _ callback: @escaping (Result<String, Error>) -> Void
)
```
