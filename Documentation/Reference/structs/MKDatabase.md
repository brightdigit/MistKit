**STRUCT**

# `MKDatabase`

```swift
public struct MKDatabase<HttpClient: MKHttpClient>
```

## Properties
### `webAuthenticationToken`

```swift
public var webAuthenticationToken: String?
```

## Methods
### `init(connection:factory:client:authenticationToken:)`

```swift
public init(connection: MKDatabaseConnection, factory: MKURLBuilderFactory? = nil, client: HttpClient, authenticationToken: String? = nil)
```

### `perform(request:_:)`

```swift
public func perform<RequestType: MKRequest, ResponseType>(
  request: RequestType,
  _ callback: @escaping ((MKResult<ResponseType, Error>) -> Void)
) where RequestType.Response == ResponseType
```
