**CLASS**

# `MKNIOHTTP1TokenClient`

```swift
public class MKNIOHTTP1TokenClient: MKTokenClient
```

## Methods
### `init(bindTo:onRedirectURL:)`

```swift
public init(bindTo: BindTo, onRedirectURL: ((URL) -> Void)? = nil)
```

### `request(_:_:)`

```swift
public func request(_ request: MKAuthenticationResponse?, _ callback: @escaping ((Result<String, Error>) -> Void))
```
