**ENUM**

# `MKResult`

```swift
public enum MKResult<Success, Failure: Error>
```

## Cases
### `success(_:)`

```swift
case success(Success)
```

### `authenticationRequired(_:)`

```swift
case authenticationRequired(MKAuthRedirect)
```

### `failure(_:)`

```swift
case failure(Failure)
```
