**PROTOCOL**

# `MKTokenManager`

```swift
public protocol MKTokenManager: AnyObject
```

## Properties
### `webAuthenticationToken`

```swift
var webAuthenticationToken: String?
```

## Methods
### `request(_:_:)`

```swift
func request(_ request: MKErrorResponse?, _ callback: @escaping (Result<String, Error>) -> Void)
```
