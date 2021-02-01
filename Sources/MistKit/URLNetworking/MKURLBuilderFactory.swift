public struct MKURLBuilderFactory {
  public init() {}
  public func builder(
    forConnection connection: MKDatabaseConnection,
    withTokenManager tokenManager: MKTokenManagerProtocol?
  ) -> MKURLBuilderProtocol {
    MKURLBuilder(
      tokenEncoder: CharacterMapEncoder(),
      connection: connection,
      tokenManager: tokenManager
    )
  }
}
