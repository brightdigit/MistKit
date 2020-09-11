**STRUCT**

# `MKDatabase`

```swift
public struct MKDatabase<HttpClient: MKHttpClient>
```

## Methods
### `setWebAuthenticationToken(_:)`

```swift
public nonmutating func setWebAuthenticationToken(_ newValue: String)
```

### `init(connection:factory:client:tokenManager:)`

```swift
public init(connection: MKDatabaseConnection, factory: MKURLBuilderFactory? = nil, client: HttpClient, tokenManager: MKTokenManager? = nil)
```

### `perform(request:returnFailedAuthentication:_:)`

```swift
public func perform<RequestType: MKRequest, ResponseType>(
  request: RequestType,
  returnFailedAuthentication: Bool = false,
  _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
) where RequestType.Response == ResponseType
```
