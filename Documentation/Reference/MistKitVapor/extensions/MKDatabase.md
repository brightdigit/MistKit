**EXTENSION**

# `MKDatabase`
```swift
public extension MKDatabase
```

## Methods
### `query(_:on:)`

```swift
func query<RecordType: MKContentRecord, EncodedType>(
  _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
  on eventLoop: EventLoop
) -> EventLoopFuture<[RecordType]> where RecordType.ContentType == EncodedType
```

### `perform(operations:on:)`

```swift
func perform<RecordType: MKContentRecord, EncodedType>(operations: ModifyRecordQueryRequest<RecordType>, on eventLoop: EventLoop) -> EventLoopFuture<ModifiedRecordQueryResult<RecordType>> where RecordType.ContentType == EncodedType
```

### `lookup(_:on:)`

```swift
func lookup<RecordType: MKContentRecord, EncodedType>(
  _ lookup: LookupRecordQueryRequest<RecordType>,
  on eventLoop: EventLoop
) -> EventLoopFuture<[RecordType]> where RecordType.ContentType == EncodedType
```

### `perform(request:returnFailedAuthentication:on:)`

```swift
func perform<RequestType: MKRequest, ResponseType>(
  request: RequestType,
  returnFailedAuthentication: Bool = false,
  on eventLoop: EventLoop
) -> EventLoopFuture<ResponseType> where RequestType.Response == ResponseType
```
