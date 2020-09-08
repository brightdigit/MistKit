public struct MKURLBuilderFactory {
  public init() {}
  public func builder(forConnection connection: MKDatabaseConnection, withWebAuthToken webAuthenticationToken: String?) -> MKURLBuilder {
    return MKURLBuilder(tokenEncoder: CharacterMapEncoder(), connection: connection, webAuthenticationToken: webAuthenticationToken)
  }
}
