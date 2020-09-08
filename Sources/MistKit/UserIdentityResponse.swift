public struct UserIdentityResponse: MKDecodable {
  public init(lookupInfo: UserIdentityLookupInfo?, userRecordName: RecordName, nameComponents: UserIdentityNameComponents?) {
    self.lookupInfo = lookupInfo
    self.userRecordName = userRecordName
    self.nameComponents = nameComponents
  }

  public let lookupInfo: UserIdentityLookupInfo?
  public let userRecordName: RecordName
  public let nameComponents: UserIdentityNameComponents?
}
