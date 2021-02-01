**CLASS**

# `User`

```swift
public final class User: Model, Content
```

## Properties
### `id`

```swift
public var id: UUID?
```

### `name`

```swift
public var name: String
```

### `passwordHash`

```swift
public var passwordHash: String
```

### `cloudKitToken`

```swift
public var cloudKitToken: String?
```

## Methods
### `init()`

```swift
public init()
```

### `init(id:name:passwordHash:)`

```swift
public init(id: UUID? = nil, name: String, passwordHash: String)
```
