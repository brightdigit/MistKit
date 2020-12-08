**STRUCT**

# `MKDatabase`

```swift
public struct MKDatabase<HttpClient: MKHttpClient>
```

## Properties
### `urlBuilder`

```swift
public let urlBuilder: MKURLBuilder
```

### `requestConfigFactory`

```swift
public let requestConfigFactory: RequestConfigurationFactoryProtocol
```

### `client`

```swift
public let client: HttpClient
```

### `resultSink`

```swift
public let resultSink: ResultSinkProtocol
```

## Methods
### `init(connection:client:factory:requestConfigFactory:resultSink:tokenManager:)`

```swift
public init(connection: MKDatabaseConnection,
            client: HttpClient,
            factory: MKURLBuilderFactory? = nil,
            requestConfigFactory: RequestConfigurationFactoryProtocol? = nil,
            resultSink: ResultSinkProtocol? = nil,
            tokenManager: MKTokenManagerProtocol? = nil)
```

### `perform(request:returnFailedAuthentication:_:)`

```swift
public func perform<RequestType: MKRequest, ResponseType>(
  request: RequestType,
  returnFailedAuthentication: Bool = false,
  _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
) where RequestType.Response == ResponseType
```
