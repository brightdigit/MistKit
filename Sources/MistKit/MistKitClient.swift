//
//  MistKitClient.swift
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
