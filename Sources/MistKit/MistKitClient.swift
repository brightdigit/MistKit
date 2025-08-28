import Foundation
import HTTPTypes
import OpenAPIRuntime
import OpenAPIURLSession

/// A client for interacting with CloudKit Web Services
public struct MistKitClient {
  /// The underlying OpenAPI client
  internal let client: Client

  /// The CloudKit container configuration
  public let configuration: MistKitConfiguration

  /// Initialize a new MistKit client
  /// - Parameter configuration: The CloudKit configuration including container,
  ///   environment, and authentication
  /// - Throws: ClientError if initialization fails
  public init(configuration: MistKitConfiguration) throws {
    self.configuration = configuration

    // Create the OpenAPI client with custom server URL and middleware
    self.client = Client(
      serverURL: configuration.serverURL,
      transport: URLSessionTransport(),
      middlewares: [
        AuthenticationMiddleware(configuration: configuration),
        LoggingMiddleware(),
      ]
    )
  }
}
