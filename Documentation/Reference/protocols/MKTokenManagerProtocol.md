**PROTOCOL**

# `MKTokenManagerProtocol`

```swift
public protocol MKTokenManagerProtocol: AnyObject
```

## Properties
### `webAuthenticationToken`

```swift
var webAuthenticationToken: String?
```

## Methods
### `request(_:_:)`

```swift
func request(_ request: MKAuthenticationResponse?, _ callback: @escaping (Result<String, Error>) -> Void)
```
