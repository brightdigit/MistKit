**EXTENSION**

# `Result`
```swift
public extension Result
```

## Properties
### `authResponse`

```swift
var authResponse: MKAuthenticationRedirect?
```

## Methods
### `tryFlatmap(recordsTo:)`

```swift
func tryFlatmap<RecordType: MKQueryRecord>(
  recordsTo _: RecordType.Type
) -> Result<[RecordType], Failure>
  where Success == FetchRecordQueryResponse, Failure == Error
```
