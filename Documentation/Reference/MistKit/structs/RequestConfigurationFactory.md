**STRUCT**

# `RequestConfigurationFactory`

```swift
public struct RequestConfigurationFactory: RequestConfigurationFactoryProtocol
```

## Methods
### `configuration(from:withURLBuilder:)`

```swift
public func configuration<RequestType>(from request: RequestType, withURLBuilder urlBuilder: MKURLBuilder) throws -> RequestConfiguration where RequestType: MKRequest
```
