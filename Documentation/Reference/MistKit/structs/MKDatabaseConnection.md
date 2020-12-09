**STRUCT**

# `MKDatabaseConnection`

```swift
public struct MKDatabaseConnection
```

## Properties
### `baseURL`

```swift
public let baseURL: URL
```

### `container`

```swift
public let container: String
```

### `environment`

```swift
public let environment: MKEnvironment
```

### `version`

```swift
public let version: MKAPIVersion
```

### `apiToken`

```swift
public let apiToken: String
```

## Methods
### `init(container:apiToken:environment:baseURL:version:)`

```swift
public init(container: String,
            apiToken: String,
            environment: MKEnvironment,
            baseURL: URL = Self.baseURL,
            version: MKAPIVersion = .v1)
```
