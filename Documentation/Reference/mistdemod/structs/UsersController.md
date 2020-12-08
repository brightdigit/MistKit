**STRUCT**

# `UsersController`

```swift
public struct UsersController: RouteCollection
```

## Methods
### `create(_:)`

```swift
public func create(_ request: Request) throws -> EventLoopFuture<HTTPStatus>
```

### `get(_:)`

```swift
public func get(_ request: Request) throws -> EventLoopFuture<MKServerResponse<UserIdentityResponse>>
```

### `boot(routes:)`

```swift
public func boot(routes: RoutesBuilder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| routes | `RoutesBuilder` to register any new routes to. |