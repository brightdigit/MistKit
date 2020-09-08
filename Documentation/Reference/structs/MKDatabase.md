**STRUCT**

# `MKDatabase`

```swift
public struct MKDatabase<HttpClient: MKHttpClient>
```

## Methods
### `init(connection:factory:client:authenticationToken:)`

```swift
public init(connection: MKDatabaseConnection, factory _: MKURLBuilderFactory, client: HttpClient, authenticationToken: String? = nil)
```

### `perform(request:_:)`

```swift
public func perform<RequestType: MKRequest, ResponseType>(
  request: RequestType,
  _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
) where RequestType.Response == ResponseType
```
