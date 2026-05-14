//
//  MistKitConfiguration+ConvenienceInitializers.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

extension MistKitConfiguration {
  /// Initialize configuration with API token only (container-level access)
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  ///   - database: The database type (default: .private)
  ///   - apiToken: The API token
  /// - Returns: A configured MistKitConfiguration for API token authentication
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
  /// - Returns: A configured MistKitConfiguration for web authentication
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
}
