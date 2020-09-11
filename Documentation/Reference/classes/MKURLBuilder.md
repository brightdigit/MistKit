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
public let tokenManager: MKTokenManager?
```

## Methods
### `init(tokenEncoder:connection:tokenManager:)`

```swift
public init(tokenEncoder: MKTokenEncoder?, connection: MKDatabaseConnection, tokenManager: MKTokenManager? = nil)
```

### `url(withPathComponents:)`

```swift
public func url(withPathComponents pathComponents: [String]) throws -> URL
```
