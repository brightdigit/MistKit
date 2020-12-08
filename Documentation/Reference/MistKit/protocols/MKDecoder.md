**PROTOCOL**

# `MKDecoder`

```swift
public protocol MKDecoder
```

## Methods
### `decode(_:from:)`

```swift
func decode<DecoableType: MKDecodable>(_ type: DecoableType.Type, from data: Data) throws -> DecoableType
```
