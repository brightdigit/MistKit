import Foundation

// MARK: - BushelConfiguration

/// Configuration for Bushel command-line tool
public struct BushelConfiguration: Sendable {
  // MARK: Lifecycle

  public init(
    containerIdentifier: String,
    environment: CloudKitEnvironment = .production,
    database: CloudKitDatabase = .private,
    apiToken: String? = nil,
    serverToServerKey: String? = nil
  ) {
    self.containerIdentifier = containerIdentifier
    self.environment = environment
    self.database = database
    self.apiToken = apiToken
    self.serverToServerKey = serverToServerKey
  }

  // MARK: Public

  // MARK: - Types

  public enum CloudKitEnvironment: String, Sendable {
    case development
    case production
  }

  public enum CloudKitDatabase: String, Sendable {
    case `public`
    case `private`
    case shared
  }

  // MARK: - Properties

  /// CloudKit container identifier (e.g., "iCloud.com.example.app")
  public let containerIdentifier: String

  /// CloudKit environment (development or production)
  public let environment: CloudKitEnvironment

  /// CloudKit database to use (public, private, or shared)
  public let database: CloudKitDatabase

  /// Optional API token for authentication
  public let apiToken: String?

  /// Optional server-to-server key for authentication
  public let serverToServerKey: String?

  // MARK: - Static Methods

  /// Loads configuration from environment variables
  public static func fromEnvironment() throws -> BushelConfiguration {
    guard let containerIdentifier = ProcessInfo.processInfo.environment["CLOUDKIT_CONTAINER_ID"] else {
      throw ConfigurationError.missingContainerIdentifier
    }

    let environmentString = ProcessInfo.processInfo.environment["CLOUDKIT_ENVIRONMENT"] ?? "production"
    let environment = CloudKitEnvironment(rawValue: environmentString) ?? .production

    let databaseString = ProcessInfo.processInfo.environment["CLOUDKIT_DATABASE"] ?? "private"
    let database = CloudKitDatabase(rawValue: databaseString) ?? .private

    let apiToken = ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"]
    let serverToServerKey = ProcessInfo.processInfo.environment["CLOUDKIT_SERVER_KEY"]

    return BushelConfiguration(
      containerIdentifier: containerIdentifier,
      environment: environment,
      database: database,
      apiToken: apiToken,
      serverToServerKey: serverToServerKey
    )
  }

  /// Loads configuration from a JSON file
  public static func fromFile(at path: String) throws -> BushelConfiguration {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(BushelConfiguration.self, from: data)
  }
}

// MARK: Codable

extension BushelConfiguration: Codable { }

// MARK: - BushelConfiguration.CloudKitEnvironment + Codable

extension BushelConfiguration.CloudKitEnvironment: Codable { }

// MARK: - BushelConfiguration.CloudKitDatabase + Codable

extension BushelConfiguration.CloudKitDatabase: Codable { }

// MARK: - ConfigurationError

public enum ConfigurationError: Error {
  case missingContainerIdentifier
  case invalidConfigurationFile(String)
  case missingAuthentication
}

// MARK: LocalizedError

extension ConfigurationError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .missingContainerIdentifier:
      return "Missing CloudKit container identifier. Set CLOUDKIT_CONTAINER_ID environment variable."
    case let .invalidConfigurationFile(path):
      return "Invalid or unreadable configuration file at: \(path)"
    case .missingAuthentication:
      return "Missing authentication. Provide either CLOUDKIT_API_TOKEN or CLOUDKIT_SERVER_KEY."
    }
  }
}
