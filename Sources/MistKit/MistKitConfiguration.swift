//
//  MistKitConfiguration.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Configuration for MistKit client
public struct MistKitConfiguration: Sendable {
  /// The CloudKit container identifier (e.g., "iCloud.com.example.app")
  public let container: String

  /// The CloudKit environment
  public let environment: Environment

  /// The CloudKit database type
  public let database: Database

  /// API Token for authentication
  public let apiToken: String

  /// Optional Web Auth Token for user authentication
  public let webAuthToken: String?

  /// Protocol version (currently "1")
  public let version: String = "1"

  /// Computed server URL based on configuration
  public var serverURL: URL {
    guard let url = URL(string: "https://api.apple-cloudkit.com") else {
      fatalError("Invalid CloudKit API URL")
    }
    return url
  }

  /// Initialize MistKit configuration
  public init(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String,
    webAuthToken: String? = nil
  ) {
    self.container = container
    self.environment = environment
    self.database = database
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
  }

  /// Creates an appropriate TokenManager based on the configuration
  /// - Returns: A TokenManager instance matching the authentication method
  public func createTokenManager() -> any TokenManager {
    if let webAuthToken = webAuthToken {
      return WebAuthTokenManager(apiToken: apiToken, webAuthToken: webAuthToken)
    } else {
      return APITokenManager(apiToken: apiToken)
    }
  }
}

// MARK: - Convenience Initializers

extension MistKitConfiguration {
  /// Initialize configuration with API token only (container-level access)
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  ///   - database: The database type (default: .private)
  ///   - apiToken: The API token
  public static func apiToken(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String
  ) -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: apiToken,
      webAuthToken: nil
    )
  }

  /// Initialize configuration with web authentication (user-specific access)
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  ///   - database: The database type (default: .private)
  ///   - apiToken: The API token
  ///   - webAuthToken: The web authentication token
  public static func webAuth(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String,
    webAuthToken: String
  ) -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: apiToken,
      webAuthToken: webAuthToken
    )
  }

  /// Initialize configuration for server-to-server authentication (public database only)
  /// Server-to-server authentication in CloudKit Web Services only supports the public database
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  /// - Note: Database is automatically set to .public as server-to-server authentication
  ///         only supports the public database in CloudKit Web Services
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public static func serverToServer(
    container: String,
    environment: Environment
  ) -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: .public,  // Server-to-server only supports public database
      apiToken: "",  // Not used with server-to-server auth
      webAuthToken: nil
    )
  }
}

// MARK: - Component Type Conversions

/// Extension to convert Environment enum to Components type
extension Environment {
  /// Convert to the generated Components.Parameters.environment type
  internal func toComponentsEnvironment() -> Components.Parameters.environment {
    switch self {
    case .development:
      return .development
    case .production:
      return .production
    }
  }
}

/// Extension to convert Database enum to Components type
extension Database {
  /// Convert to the generated Components.Parameters.database type
  internal func toComponentsDatabase() -> Components.Parameters.database {
    switch self {
    case .public:
      return ._public
    case .private:
      return ._private
    case .shared:
      return .shared
    }
  }
}
