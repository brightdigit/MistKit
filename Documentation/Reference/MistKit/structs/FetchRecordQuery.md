**STRUCT**

# `FetchRecordQuery`

```swift
public struct FetchRecordQuery<QueryType: MKQueryProtocol>: MKEncodable
```

## Properties
### `query`

```swift
public let query: QueryType
```

### `desiredKeys`

```swift
public let desiredKeys: [String]?
```

### `numbersAsStrings`

```swift
public let numbersAsStrings: Bool = true
```

## Methods
### `init(query:)`

```swift
public init(query: QueryType)
```
