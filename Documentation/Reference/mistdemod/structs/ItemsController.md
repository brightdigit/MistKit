**STRUCT**

# `ItemsController`

```swift
public struct ItemsController: RouteCollection
```

## Methods
### `list(_:)`

```swift
public func list(_ request: Request) -> EventLoopFuture<MKServerResponse<[TodoItemModel]>>
```

### `create(_:)`

```swift
public func create(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>>
```

### `delete(_:)`

```swift
public func delete(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>>
```

### `find(_:)`

```swift
public func find(_ request: Request) throws -> EventLoopFuture<MKServerResponse<[TodoItemModel]>>
```

### `rename(_:)`

```swift
public func rename(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>>
```

### `boot(routes:)`

```swift
public func boot(routes: RoutesBuilder) throws
```

#### Parameters

| Name | Description |
| ---- | ----------- |
| routes | `RoutesBuilder` to register any new routes to. |