**PROTOCOL**

# `MKTokenClient`

```swift
public protocol MKTokenClient: AnyObject
```

## Methods
### `request(_:_:)`

```swift
func request(
  _ request: MKAuthenticationRedirect?,
  _ callback: @escaping (Result<String, Error>) -> Void
)
```
