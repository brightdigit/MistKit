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
}
