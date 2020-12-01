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

### `tokenManager`

```swift
public let tokenManager: MKTokenManagerProtocol?
```

## Methods
### `init(tokenEncoder:connection:tokenManager:)`

```swift
public init(tokenEncoder: MKTokenEncoder?, connection: MKDatabaseConnection, tokenManager: MKTokenManagerProtocol? = nil)
```

### `url(withPathComponents:)`

```swift
public func url(withPathComponents pathComponents: [String]) throws -> URL
```
