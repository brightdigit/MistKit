**STRUCT**

# `MKURLRequest`

```swift
public struct MKURLRequest: MKHttpRequest
```

## Properties
### `urlRequest`

```swift
public let urlRequest: URLRequest
```

### `urlSession`

```swift
public let urlSession: URLSession
```

## Methods
### `execute(_:)`

```swift
public func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void))
```
