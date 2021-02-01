**STRUCT**

# `CharacterMapEncoder`

```swift
public struct CharacterMapEncoder: MKTokenEncoder
```

## Properties
### `characterMap`

```swift
public let characterMap: [String: String]
```

## Methods
### `init(characterMap:)`

```swift
public init(characterMap: [String: String] = defaultCharacterMap)
```

### `encode(_:)`

```swift
public func encode(_ token: String) -> String
```
