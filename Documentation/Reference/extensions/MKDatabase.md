**EXTENSION**

# `MKDatabase`
```swift
public extension MKDatabase where HttpClient == MKURLSessionClient
```

## Methods
### `init(connection:factory:tokenManager:session:)`

```swift
init(connection: MKDatabaseConnection,
     factory: MKURLBuilderFactory? = nil,
     tokenManager: MKTokenManagerProtocol? = nil,
     session: URLSession? = nil)
```

### `query(_:_:)`

```swift
public func query<RecordType: MKQueryRecord>(
  _ query: FetchRecordQueryRequest<MKQuery<RecordType>>,
  _ callback: @escaping ((Result<[RecordType], Error>) -> Void)
)
```

### `perform(operations:_:)`

```swift
public func perform<RecordType: MKQueryRecord>(
  operations: ModifyRecordQueryRequest<RecordType>,
  _ callback: @escaping ((Result<ModifiedRecordQueryResult<RecordType>, Error>) -> Void)
)
```

### `lookup(_:_:)`

```swift
public func lookup<RecordType: MKQueryRecord>(
  _ lookup: LookupRecordQueryRequest<RecordType>,
  _ callback: @escaping ((Result<[RecordType], Error>) -> Void)
)
```
