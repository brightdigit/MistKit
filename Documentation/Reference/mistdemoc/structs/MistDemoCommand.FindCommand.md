**STRUCT**

# `MistDemoCommand.FindCommand`

```swift
struct FindCommand: ParsableAsyncCommand
```

## Properties
### `recordNames`

```swift
public var recordNames: [UUID] = []
```

### `record`

```swift
public var record: Bool = false
```

## Methods
### `init()`

```swift
public init()
```

### `runAsync(_:)`

```swift
public func runAsync(_ completed: @escaping (Error?) -> Void)
```
