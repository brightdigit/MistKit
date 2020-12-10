**STRUCT**

# `ResultTransformer`

```swift
public struct ResultTransformer: ResultTransformerProtocol
```

## Methods
### `data(fromResult:setWebAuthenticationToken:)`

```swift
public func data(
  fromResult result: Result<MKHttpResponse, Error>,
  setWebAuthenticationToken: (String) -> Void
) -> Result<Data, Error>
```
