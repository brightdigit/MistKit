**PROTOCOL**

# `ResultTransformerProtocol`

```swift
public protocol ResultTransformerProtocol
```

## Methods
### `data(fromResult:setWebAuthenticationToken:)`

```swift
func data(fromResult result: Result<MKHttpResponse, Error>, setWebAuthenticationToken: (String) -> Void) -> Result<Data, Error>
```
