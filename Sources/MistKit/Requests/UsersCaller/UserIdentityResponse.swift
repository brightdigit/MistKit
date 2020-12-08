public struct UserIdentityResponse: MKDecodable, Codable {
  public let lookupInfo: UserIdentityLookupInfo?
  public let userRecordName: RecordName
  public let nameComponents: UserIdentityNameComponents?
  public init(
    lookupInfo: UserIdentityLookupInfo?,
    userRecordName: RecordName,
    nameComponents: UserIdentityNameComponents?
  ) {
    self.lookupInfo = lookupInfo
    self.userRecordName = userRecordName
    self.nameComponents = nameComponents
  }
}
