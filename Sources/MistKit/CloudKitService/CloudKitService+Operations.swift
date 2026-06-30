//
//  CloudKitService+Operations.swift
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
internal import MistKitOpenAPI
internal import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

#if !os(WASI)
  internal import OpenAPIURLSession
#endif

extension CloudKitService {
  /// Query records from the default zone with pagination support.
  ///
  /// The unified ``Query`` value carries the `recordType` plus any
  /// ``QueryFilter`` predicates and ``QuerySort`` descriptors. The same
  /// value can be embedded in a subscription via
  /// ``SubscriptionInfo/Kind/query(_:)``.
  ///
  /// - Parameters:
  ///   - query: The query to execute.
  ///   - limit: Maximum records to return (defaults to `defaultQueryLimit`).
  ///   - desiredKeys: Optional list of field names to fetch.
  ///   - continuationMarker: Marker from a previous ``QueryResult`` to
  ///     fetch the next page.
  ///   - zoneWide: When true, query across all zones rather than a single zone.
  ///   - numbersAsStrings: When true, numeric field values are returned as strings (avoids
  ///     JavaScript precision loss for `INT64`).
  ///   - database: The CloudKit database scope to query.
  /// - Returns: A ``QueryResult`` with matching records and an optional
  ///   continuation marker.
  /// - Throws: ``CloudKitError`` if validation fails or the request fails.
  public func queryRecords(
    _ query: Query,
    limit: Int? = nil,
    desiredKeys: [String]? = nil,
    continuationMarker: String? = nil,
    zoneWide: Bool? = nil,
    numbersAsStrings: Bool? = nil,
    database: Database
  ) async throws(CloudKitError) -> QueryResult {
    let effectiveLimit = limit ?? defaultQueryLimit

    do {
      let client = try self.client(for: database)
      let response = try await client.queryRecords(
        .init(
          path: Operations.queryRecords.Input.Path(
            containerIdentifier: containerIdentifier,
            environment: environment,
            database: database
          ),
          body: .json(
            .init(
              zoneID: .init(zoneName: "_defaultZone"),
              resultsLimit: effectiveLimit,
              query: query.schema,
              desiredKeys: desiredKeys,
              continuationMarker: continuationMarker,
              zoneWide: zoneWide,
              numbersAsStrings: numbersAsStrings
            )
          )
        )
      )

      let recordsData: Components.Schemas.QueryResponse =
        try await responseProcessor.processQueryRecordsResponse(response)
      return try QueryResult(from: recordsData)
    } catch {
      throw mapToCloudKitError(error, context: "queryRecords")
    }
  }
}
