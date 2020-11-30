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
) -> EventLoopFuture<MKServerResponse<[EncodedType]>> where RecordType.ContentType == EncodedType
```

### `perform(operations:on:)`

```swift
func perform<RecordType: MKContentRecord, EncodedType>(operations: ModifyRecordQueryRequest<RecordType>, on eventLoop: EventLoop) -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<EncodedType>>> where RecordType.ContentType == EncodedType
```
