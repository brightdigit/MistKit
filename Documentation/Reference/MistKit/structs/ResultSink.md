**STRUCT**

# `ResultSink`

```swift
public struct ResultSink: ResultSinkProtocol
```

## Properties
### `dataTransformer`

```swift
public let dataTransformer: ResultTransformerProtocol
```

### `decoder`

```swift
public let decoder: MKDecoder
```

## Methods
### `init(dataTransformer:decoder:)`

```swift
public init(
  dataTransformer: ResultTransformerProtocol? = nil,
  decoder: MKDecoder? = nil
)
```

### `response(fromResult:ofRequest:shouldFailAuth:)`

```swift
public func response<RequestType, ResponseType>(
  fromResult dataResult: Result<Data, Error>,
  ofRequest _: RequestType,
  shouldFailAuth _: Bool
) -> Result<ResponseType, Error>
  where RequestType: MKRequest, ResponseType == RequestType.Response
```

### `database(_:request:completedWith:shouldFailAuth:_:)`

```swift
public func database<RequestType, ResponseType, HttpClientType>(
  _ database: MKDatabase<HttpClientType>,
  request: RequestType,
  completedWith result: Result<MKHttpResponse, Error>,
  shouldFailAuth: Bool,
  _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
) where RequestType: MKRequest,
  ResponseType == RequestType.Response,
  HttpClientType: MKHttpClient
```
