**PROTOCOL**

# `ResultSinkProtocol`

```swift
public protocol ResultSinkProtocol
```

## Methods
### `database(_:request:completedWith:shouldFailAuth:_:)`

```swift
func database<RequestType: MKRequest, ResponseType, HttpClientType: MKHttpClient>(
  _ database: MKDatabase<HttpClientType>,
  request: RequestType,
  completedWith result: Result<MKHttpResponse, Error>,
  shouldFailAuth: Bool,
  _ callback: @escaping ((Result<ResponseType, Error>) -> Void)
) where RequestType.Response == ResponseType
```
