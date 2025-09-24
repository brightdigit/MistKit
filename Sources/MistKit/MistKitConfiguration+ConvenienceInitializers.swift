//
//  MistKitConfiguration+ConvenienceInitializers.swift
//  MistKit
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

#if canImport(Foundation)
  public import Foundation
#endif

// MARK: - Convenience Initializers

extension MistKitConfiguration {
  /// Initialize configuration with API token only (container-level access)
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  ///   - database: The database type (default: .private)
  ///   - apiToken: The API token
  ///   - storage: Optional token storage for persistence
  public static func apiToken(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String,
    storage: (any TokenStorage)? = nil
  ) -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: apiToken,
      webAuthToken: nil,
      keyID: nil,
      privateKeyData: nil,
      storage: storage,
      dependencyContainer: nil
    )
  }

  /// Initialize configuration with web authentication (user-specific access)
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  ///   - database: The database type (default: .private)
  ///   - apiToken: The API token
  ///   - webAuthToken: The web authentication token
  ///   - storage: Optional token storage for persistence
  public static func webAuth(
    container: String,
    environment: Environment,
    database: Database = .private,
    apiToken: String,
    webAuthToken: String,
    storage: (any TokenStorage)? = nil
  ) -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: database,
      apiToken: apiToken,
      webAuthToken: webAuthToken,
      keyID: nil,
      privateKeyData: nil,
      storage: storage,
      dependencyContainer: nil
    )
  }

  /// Initialize configuration for server-to-server authentication (public database only)
  /// Server-to-server authentication in CloudKit Web Services only supports the public database
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  ///   - keyID: The key identifier from Apple Developer Console
  ///   - privateKeyData: The private key as raw data (32 bytes for P-256)
  ///   - storage: Optional token storage for persistence
  /// - Note: Database is automatically set to .public as server-to-server authentication
  ///         only supports the public database in CloudKit Web Services
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public static func serverToServer(
    container: String,
    environment: Environment,
    keyID: String,
    privateKeyData: Data,
    storage: (any TokenStorage)? = nil
  ) -> MistKitConfiguration {
    MistKitConfiguration(
      container: container,
      environment: environment,
      database: .public,  // Server-to-server only supports public database
      apiToken: "",  // Not used with server-to-server auth
      webAuthToken: nil,
      keyID: keyID,
      privateKeyData: privateKeyData,
      storage: storage,
      dependencyContainer: nil
    )
  }
}
