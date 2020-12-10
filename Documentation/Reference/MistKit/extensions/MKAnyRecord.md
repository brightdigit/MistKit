**EXTENSION**

# `MKAnyRecord`
```swift
public extension MKAnyRecord
```

## Properties
### `information`

```swift
var information: String
```

## Methods
### `data(fromKey:)`

```swift
func data(fromKey key: String) throws -> Data
```

### `string(fromKey:)`

```swift
func string(fromKey key: String) throws -> String
```

### `integer(fromKey:)`

```swift
func integer(fromKey key: String) throws -> Int64
```

### `date(fromKey:)`

```swift
func date(fromKey key: String) throws -> Date
```

### `double(fromKey:)`

```swift
func double(fromKey key: String) throws -> Double
```

### `location(fromKey:)`

```swift
func location(fromKey key: String) throws -> MKLocation
```

### `asset(fromKey:)`

```swift
func asset(fromKey key: String) throws -> MKAsset
```

### `dataIfExists(fromKey:)`

```swift
func dataIfExists(fromKey key: String) throws -> Data?
```

### `stringIfExists(fromKey:)`

```swift
func stringIfExists(fromKey key: String) throws -> String?
```

### `integerIfExists(fromKey:)`

```swift
func integerIfExists(fromKey key: String) throws -> Int64?
```

### `dateIfExists(fromKey:)`

```swift
func dateIfExists(fromKey key: String) throws -> Date?
```

### `doubleIfExists(fromKey:)`

```swift
func doubleIfExists(fromKey key: String) throws -> Double?
```

### `locationIfExists(fromKey:)`

```swift
func locationIfExists(fromKey key: String) throws -> MKLocation?
```

### `assetIfExists(fromKey:)`

```swift
func assetIfExists(fromKey key: String) throws -> MKAsset?
```
