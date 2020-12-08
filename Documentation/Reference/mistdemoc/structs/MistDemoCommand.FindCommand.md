**STRUCT**

# `MistDemoCommand.FindCommand`

```swift
struct FindCommand: ParsableAsyncCommand
```

## Properties
### `options`

```swift
@OptionGroup public var options: MistDemoArguments
```

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
