**EXTENSION**

# `EventLoopFuture`
```swift
public extension EventLoopFuture
```

## Methods
### `content()`

```swift
func content<RecordType: MKContentRecord, ContentType>()
  -> EventLoopFuture<MKServerResponse<[ContentType]>>
  where Value == [RecordType], RecordType.ContentType == ContentType
```

### `content()`

```swift
func content<RecordType: MKContentRecord, ContentType>()
  -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<ContentType>>>
  where Value == ModifiedRecordQueryResult<RecordType>, RecordType.ContentType == ContentType
```

### `mistKitResponse()`

```swift
func mistKitResponse() -> EventLoopFuture<MKServerResponse<Value>>
```
