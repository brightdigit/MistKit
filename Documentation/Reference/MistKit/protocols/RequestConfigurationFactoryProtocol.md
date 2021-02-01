**PROTOCOL**

# `RequestConfigurationFactoryProtocol`

```swift
public protocol RequestConfigurationFactoryProtocol
```

## Methods
### `configuration(from:withURLBuilder:)`

```swift
func configuration<RequestType: MKRequest>(
  from request: RequestType,
  withURLBuilder urlBuilder: MKURLBuilderProtocol
) throws -> RequestConfiguration
```
