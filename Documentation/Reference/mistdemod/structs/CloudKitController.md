**STRUCT**

# `CloudKitController`

```swift
public struct CloudKitController: RouteCollection
```

## Methods
### `token(_:)`

```swift
public func token(_ request: Request) -> EventLoopFuture<HTTPStatus>
```

### `boot(routes:)`

```swift
public func boot(routes: RoutesBuilder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| routes | `RoutesBuilder` to register any new routes to. |