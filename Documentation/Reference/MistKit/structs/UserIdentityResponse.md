**STRUCT**

# `UserIdentityResponse`

```swift
public struct UserIdentityResponse: MKDecodable, Codable
```

## Properties
### `lookupInfo`

```swift
public let lookupInfo: UserIdentityLookupInfo?
```

### `userRecordName`

```swift
public let userRecordName: RecordName
```

### `nameComponents`

```swift
public let nameComponents: UserIdentityNameComponents?
```

## Methods
### `init(lookupInfo:userRecordName:nameComponents:)`

```swift
public init(
  lookupInfo: UserIdentityLookupInfo?,
  userRecordName: RecordName,
  nameComponents: UserIdentityNameComponents?
)
```
