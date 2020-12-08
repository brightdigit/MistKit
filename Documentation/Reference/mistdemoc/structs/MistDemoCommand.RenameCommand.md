**STRUCT**

# `MistDemoCommand.RenameCommand`

```swift
struct RenameCommand: ParsableAsyncCommand
```

## Properties
### `options`

```swift
@OptionGroup public var options: MistDemoArguments
```

### `recordName`

```swift
public var recordName: UUID
```

### `newTitle`

```swift
public var newTitle: String
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
