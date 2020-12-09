import Foundation

public struct MKDatabaseConnection {
  // swiftlint:disable force_unwrapping
  public static let baseURL = URL(
    string: "https://api.apple-cloudkit.com/database"
  )!
  // swiftlint:enable force_unwrapping

  public let baseURL: URL
  public let container: String
  public let environment: MKEnvironment
  public let version: MKAPIVersion
  public let apiToken: String

  public init(container: String,
              apiToken: String,
              environment: MKEnvironment,
              baseURL: URL = Self.baseURL,
              version: MKAPIVersion = .v1) {
    self.baseURL = baseURL
    self.container = container
    self.environment = environment
    self.version = version
    self.apiToken = apiToken
  }
}
