**STRUCT**

# `MistDemoCommand.NewCommand`

```swift
struct NewCommand: ParsableAsyncCommand
```

## Properties
### `options`

```swift
@OptionGroup public var options: MistDemoArguments
```

### `title`

```swift
@Argument public var title: String
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
