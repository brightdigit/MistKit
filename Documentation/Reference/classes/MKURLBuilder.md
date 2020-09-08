**CLASS**

# `MKURLBuilder`

```swift
public class MKURLBuilder
```

## Properties
### `tokenEncoder`

```swift
public let tokenEncoder: MKTokenEncoder?
```

### `connection`

```swift
public let connection: MKDatabaseConnection
```

### `webAuthenticationToken`

```swift
public var webAuthenticationToken: String?
```

## Methods
### `init(tokenEncoder:connection:webAuthenticationToken:)`

```swift
public init(tokenEncoder: MKTokenEncoder?, connection: MKDatabaseConnection, webAuthenticationToken: String? = nil)
```

### `url(withPathComponents:)`

```swift
public func url(withPathComponents pathComponents: [String]) throws -> URL
```
