**CLASS**

# `MKTokenManager`

```swift
public class MKTokenManager: MKTokenManagerProtocol
```

## Properties
### `storage`

```swift
public let storage: MKTokenStorage
```

### `client`

```swift
public let client: MKTokenClient
```

### `webAuthenticationToken`

```swift
public var webAuthenticationToken: String?
```

## Methods
### `init(storage:client:)`

```swift
public init(storage: MKTokenStorage, client: MKTokenClient)
```

### `request(_:_:)`

```swift
public func request(_ request: MKAuthenticationResponse?, _ callback: @escaping (Result<String, Error>) -> Void)
```
