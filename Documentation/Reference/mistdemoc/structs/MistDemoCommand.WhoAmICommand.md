**STRUCT**

# `MistDemoCommand.WhoAmICommand`

```swift
struct WhoAmICommand: ParsableAsyncCommand
```

## Properties
### `options`

```swift
@OptionGroup public private(set) var options: MistDemoArguments
```

## Methods
### `runAsync(_:)`

```swift
public func runAsync(_ completed: @escaping (Error?) -> Void)
```

### `init()`

```swift
public init()
```
