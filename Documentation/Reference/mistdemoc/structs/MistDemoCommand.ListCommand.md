**STRUCT**

# `MistDemoCommand.ListCommand`

```swift
struct ListCommand: ParsableAsyncCommand
```

## Properties
### `options`

```swift
@OptionGroup public var options: MistDemoArguments
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
