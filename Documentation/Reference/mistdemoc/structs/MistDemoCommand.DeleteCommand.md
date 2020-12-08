**STRUCT**

# `MistDemoCommand.DeleteCommand`

```swift
struct DeleteCommand: ParsableAsyncCommand
```

## Properties
### `recordNames`

```swift
public var recordNames: [UUID] = []
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
