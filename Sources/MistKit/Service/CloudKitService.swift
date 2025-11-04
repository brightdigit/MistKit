//
//  CloudKitService.swift
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

import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

/// Service for interacting with CloudKit Web Services
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct CloudKitService: Sendable {
  /// The CloudKit container identifier
  public let containerIdentifier: String
  /// The API token for authentication
  public let apiToken: String
  /// The CloudKit environment (development or production)
  public let environment: Environment
  /// The CloudKit database (public, private, or shared)
  public let database: Database

  internal let mistKitClient: MistKitClient
  internal let responseProcessor = CloudKitResponseProcessor()
  internal var client: Client {
    mistKitClient.client
  }
}

// MARK: - Private Helper Methods

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Create a standard path for getCurrentUser requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  internal func createGetCurrentUserPath(containerIdentifier: String)
    -> Operations.getCurrentUser.Input.Path
  {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: environment.toComponentsEnvironment(),
      database: database.toComponentsDatabase()
    )
  }

  /// Create a standard path for listZones requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  internal func createListZonesPath(containerIdentifier: String)
    -> Operations.listZones.Input.Path
  {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: environment.toComponentsEnvironment(),
      database: database.toComponentsDatabase()
    )
  }

  /// Create a standard path for queryRecords requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  internal func createQueryRecordsPath(
    containerIdentifier: String
  ) -> Operations.queryRecords.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: environment.toComponentsEnvironment(),
      database: database.toComponentsDatabase()
    )
  }

  /// Create a standard path for modifyRecords requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  internal func createModifyRecordsPath(
    containerIdentifier: String
  ) -> Operations.modifyRecords.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: environment.toComponentsEnvironment(),
      database: database.toComponentsDatabase()
    )
  }

  /// Create a standard path for lookupRecords requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  internal func createLookupRecordsPath(
    containerIdentifier: String
  ) -> Operations.lookupRecords.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: environment.toComponentsEnvironment(),
      database: database.toComponentsDatabase()
    )
  }
}
