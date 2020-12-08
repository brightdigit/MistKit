import Foundation

public struct MKDatabaseConnection {
  public static let baseURL = URL(
    string: "https://api.apple-cloudkit.com/database"
  )!
  public let container: String
  public let environment: MKEnvironment
  public let version: MKAPIVersion
  public let apiToken: String

  public init(container: String,
              apiToken: String,
              environment: MKEnvironment,
              version: MKAPIVersion = .v1) {
    self.container = container
    self.environment = environment
    self.version = version
    self.apiToken = apiToken
  }
}
