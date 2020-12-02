**EXTENSION**

# `MKDatabase`
```swift
public extension MKDatabase
```

## Methods
### `query(_:on:)`

```swift
func query<RecordType>(
  _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
  on eventLoop: EventLoop
) -> EventLoopFuture<[RecordType]>
```

### `perform(operations:on:)`

```swift
func perform<RecordType>(
  operations: ModifyRecordQueryRequest<RecordType>,
  on eventLoop: EventLoop
)
  -> EventLoopFuture<ModifiedRecordQueryResult<RecordType>>
```

### `lookup(_:on:)`

```swift
func lookup<RecordType>(
  _ lookup: LookupRecordQueryRequest<RecordType>,
  on eventLoop: EventLoop
) -> EventLoopFuture<[RecordType]>
```

### `perform(request:returnFailedAuthentication:on:)`

```swift
func perform<RequestType: MKRequest, ResponseType>(
  request: RequestType,
  returnFailedAuthentication: Bool = false,
  on eventLoop: EventLoop
) -> EventLoopFuture<ResponseType> where RequestType.Response == ResponseType
```
