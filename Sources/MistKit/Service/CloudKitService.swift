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
public struct CloudKitService {
  /// The CloudKit container identifier
  public let containerIdentifier: String
  /// The API token for authentication
  public let apiToken: String
  /// The CloudKit environment (development or production)
  public let environment: Environment
  /// The CloudKit database (public, private, or shared)
  public let database: Database

  private let mistKitClient: MistKitClient
  private let responseProcessor = CloudKitResponseProcessor()
  private var client: Client {
    mistKitClient.client
  }

  /// Initialize CloudKit service with web authentication
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(containerIdentifier: String, apiToken: String, webAuthToken: String) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = apiToken
    self.environment = .development
    self.database = .private

    let config = MistKitConfiguration(
      container: containerIdentifier,
      environment: .development,
      database: .private,
      apiToken: apiToken,
      webAuthToken: webAuthToken,
      keyID: nil,
      privateKeyData: nil,
      storage: nil,
      dependencyContainer: nil
    )
    self.mistKitClient = try MistKitClient(configuration: config)
  }

  /// Initialize CloudKit service with API-only authentication
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(containerIdentifier: String, apiToken: String) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = apiToken
    self.environment = .development
    self.database = .public  // API-only supports public database

    let config = MistKitConfiguration(
      container: containerIdentifier,
      environment: .development,
      database: .public,  // API-only supports public database
      apiToken: apiToken,
      webAuthToken: nil,
      keyID: nil,
      privateKeyData: nil,
      storage: nil,
      dependencyContainer: nil
    )
    self.mistKitClient = try MistKitClient(configuration: config)
  }

  /// Initialize CloudKit service with a custom TokenManager
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  public init(
    containerIdentifier: String, tokenManager: any TokenManager,
    environment: Environment = .development, database: Database = .private
  ) throws {
    self.containerIdentifier = containerIdentifier
    self.apiToken = ""  // Not used when providing TokenManager directly
    self.environment = environment
    self.database = database

    self.mistKitClient = try MistKitClient(
      container: containerIdentifier,
      environment: environment,
      database: database,
      tokenManager: tokenManager
    )
  }

  /// Fetch current user information
  public func fetchCurrentUser() async throws -> UserInfo {
    let response = try await client.getCurrentUser(
      .init(
        path: createGetCurrentUserPath(containerIdentifier: containerIdentifier)
      )
    )

    let userData: Components.Schemas.UserResponse =
      try await responseProcessor.processGetCurrentUserResponse(response)
    return UserInfo(from: userData)
  }

  /// List zones in the user's private database
  public func listZones() async throws -> [ZoneInfo] {
    let response = try await client.listZones(
      .init(
        path: createListZonesPath(containerIdentifier: containerIdentifier)
      )
    )

    let zonesData: Components.Schemas.ZonesListResponse =
      try await responseProcessor.processListZonesResponse(response)
    return zonesData.zones?.compactMap { zone in
      guard let zoneID = zone.zoneID else {
        return nil
      }
      return ZoneInfo(
        zoneName: zoneID.zoneName ?? "Unknown",
        ownerRecordName: zoneID.ownerName,
        capabilities: []
      )
    } ?? []
  }

  /// Query records from the default zone
  public func queryRecords(recordType: String, limit: Int = 10) async throws -> [RecordInfo] {
    let response = try await client.queryRecords(
      .init(
        path: createQueryRecordsPath(containerIdentifier: containerIdentifier),
        body: .json(
          .init(
            zoneID: .init(zoneName: "_defaultZone"),
            resultsLimit: limit,
            query: .init(
              recordType: recordType,
              sortBy: [
                //                            .init(
                //                                fieldName: "modificationDate",
                //                                ascending: false
                //                            )
              ]
            )
          )
        )
      )
    )

    let recordsData: Components.Schemas.QueryResponse =
      try await responseProcessor.processQueryRecordsResponse(response)
    return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
  }
}

// MARK: - Private Helper Methods

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Create a standard path for getCurrentUser requests
  /// - Parameter containerIdentifier: The container identifier
  /// - Returns: A configured path for the request
  fileprivate func createGetCurrentUserPath(containerIdentifier: String)
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
  fileprivate func createListZonesPath(containerIdentifier: String)
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
  fileprivate func createQueryRecordsPath(containerIdentifier: String)
    -> Operations.queryRecords.Input.Path
  {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: environment.toComponentsEnvironment(),
      database: database.toComponentsDatabase()
    )
  }

  /// Process getCurrentUser response
  /// - Parameter response: The response to process
  /// - Returns: The extracted user data
  /// - Throws: CloudKitError for various error conditions
}
