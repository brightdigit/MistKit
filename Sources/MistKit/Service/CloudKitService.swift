//
//  CloudKitService.swift
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
internal import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

#if !os(WASI)
  internal import OpenAPIURLSession
#endif

/// Service for interacting with CloudKit Web Services.
///
/// `CloudKitService` is configured with a CloudKit container identifier, an
/// `Environment`, and a `Credentials` value that may carry server-to-server
/// material, API/web-auth material, or both. The database to target is chosen
/// **per call** on each operation that supports multiple databases; user-identity
/// endpoints (e.g. `fetchCaller`) hard-code `.public` since CloudKit only
/// accepts those routes against the public database.
///
/// At dispatch time the service resolves the appropriate token manager from
/// `Credentials` based on the target database and whether the operation
/// requires user-context auth. A single service can therefore serve, for
/// example, public-database record reads via server-to-server signing **and**
/// `fetchCaller` via web-auth from one fully-populated `Credentials`.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct CloudKitService: Sendable {
  /// CloudKit's maximum number of records returned per query/modify request.
  internal static let maxRecordsPerRequest: Int = 200

  /// The CloudKit container identifier
  public let containerIdentifier: String
  /// The CloudKit environment (development or production)
  public let environment: Environment

  /// Default limit for query operations (1-200, default: 100)
  internal let defaultQueryLimit: Int = 100

  internal let responseProcessor = CloudKitResponseProcessor()

  /// Resolved at construction from `Credentials`. `nil` when this service
  /// was built with a caller-supplied fixed `tokenManager`.
  internal let credentials: Credentials?

  /// Caller-supplied token manager that overrides per-call resolution.
  /// Set by the bespoke `tokenManager:` initializer for tests and special
  /// cases; otherwise `nil`.
  internal let fixedTokenManager: (any TokenManager)?

  /// Transport used for every dispatched request. Each operation builds a
  /// fresh OpenAPI `Client` against this transport with the resolved token
  /// manager wired into its middleware chain.
  internal let transport: any ClientTransport
}

// MARK: - Path builders

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  internal func createGetCallerPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.getCaller.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createListZonesPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.listZones.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createQueryRecordsPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.queryRecords.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createModifyRecordsPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.modifyRecords.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createLookupRecordsPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.lookupRecords.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createLookupZonesPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.lookupZones.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createFetchRecordChangesPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.fetchRecordChanges.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createUploadAssetsPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.uploadAssets.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createDiscoverUserIdentitiesPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.discoverUserIdentities.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createDiscoverAllUserIdentitiesPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.discoverAllUserIdentities.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createLookupUsersByEmailPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.lookupUsersByEmail.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createLookupUsersByRecordNamePath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.lookupUsersByRecordName.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }

  internal func createFetchZoneChangesPath(
    containerIdentifier: String,
    database: Database
  ) -> Operations.fetchZoneChanges.Input.Path {
    .init(
      version: "1",
      container: containerIdentifier,
      environment: .init(from: environment),
      database: .init(from: database)
    )
  }
}
