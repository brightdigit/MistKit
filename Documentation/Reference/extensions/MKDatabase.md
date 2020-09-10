**EXTENSION**

# `MKDatabase`
```swift
extension MKDatabase
```

## Methods
### `query(_:_:)`

```swift
public func query<RecordType: MKQueryRecord>(
  _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
  _ callback: @escaping ((MKResult<[RecordType], Error>) -> Void)
)
```
