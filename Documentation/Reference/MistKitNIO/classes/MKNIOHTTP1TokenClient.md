**CLASS**

# `MKNIOHTTP1TokenClient`

```swift
public class MKNIOHTTP1TokenClient: MKTokenClient
```

## Properties
### `channel`

```swift
public var channel: Channel?
```

### `bindTo`

```swift
public let bindTo: BindTo
```

### `onRedirectURL`

```swift
public let onRedirectURL: (URL) -> Void
```

## Methods
### `init(bindTo:onRedirectURL:)`

```swift
public init(bindTo: BindTo, onRedirectURL: ((URL) -> Void)? = nil)
```

### `request(_:_:)`

```swift
public func request(_ request: MKAuthenticationRedirect?, _ callback: @escaping ((Result<String, Error>) -> Void))
```
