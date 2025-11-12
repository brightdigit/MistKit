//
//  CloudKitService+Operations.swift
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

// Helper for stderr output
private func printToStderr(_ message: String) {
  fputs(message + "\n", stderr)
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Fetch current user information
  public func fetchCurrentUser() async throws(CloudKitError) -> UserInfo {
    do {
      let response = try await client.getCurrentUser(
        .init(
          path: createGetCurrentUserPath(containerIdentifier: containerIdentifier)
        )
      )

      let userData: Components.Schemas.UserResponse =
        try await responseProcessor.processGetCurrentUserResponse(response)
      return UserInfo(from: userData)
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 500,
        rawResponse: error.localizedDescription
      )
    }
  }

  /// List zones in the user's private database
  public func listZones() async throws(CloudKitError) -> [ZoneInfo] {
    do {
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
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 500,
        rawResponse: error.localizedDescription
      )
    }
  }

  /// Query records from the default zone
  public func queryRecords(
    recordType: String,
    filters: [QueryFilter]? = nil,
    sortBy: [QuerySort]? = nil,
    limit: Int = 10,
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    let componentsFilters = filters?.map { $0.toComponentsFilter() }
    let componentsSorts = sortBy?.map { $0.toComponentsSort() }

    do {
      let response = try await client.queryRecords(
        .init(
          path: createQueryRecordsPath(containerIdentifier: containerIdentifier),
          body: .json(
            .init(
              zoneID: .init(zoneName: "_defaultZone"),
              resultsLimit: limit,
              query: .init(
                recordType: recordType,
                filterBy: componentsFilters,
                sortBy: componentsSorts
              ),
              desiredKeys: desiredKeys
            )
          )
        )
      )

      let recordsData: Components.Schemas.QueryResponse =
        try await responseProcessor.processQueryRecordsResponse(response)
      return recordsData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch let decodingError as DecodingError {
      // Log detailed decoding error information
      MistKitLogger.logError(
        "JSON decoding failed in queryRecords: \(decodingError)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )

      // Also print to stderr for debugging
      printToStderr("⚠️ DECODING ERROR DETAILS:")
      printToStderr("  Error: \(decodingError)")

      // Print detailed context based on error type
      switch decodingError {
      case .keyNotFound(let key, let context):
        printToStderr("  Missing key: \(key)")
        printToStderr("  Context: \(context.debugDescription)")
        printToStderr("  Coding path: \(context.codingPath)")
      case .typeMismatch(let type, let context):
        printToStderr("  Type mismatch: expected \(type)")
        printToStderr("  Context: \(context.debugDescription)")
        printToStderr("  Coding path: \(context.codingPath)")
      case .valueNotFound(let type, let context):
        printToStderr("  Value not found: expected \(type)")
        printToStderr("  Context: \(context.debugDescription)")
        printToStderr("  Coding path: \(context.codingPath)")
      case .dataCorrupted(let context):
        printToStderr("  Data corrupted")
        printToStderr("  Context: \(context.debugDescription)")
        printToStderr("  Coding path: \(context.codingPath)")
      @unknown default:
        printToStderr("  Unknown decoding error type")
      }

      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 500,
        rawResponse: "Decoding error: \(decodingError)"
      )
    } catch {
      // Log unexpected errors
      MistKitLogger.logError(
        "Unexpected error in queryRecords: \(error)",
        logger: MistKitLogger.api,
        shouldRedact: false
      )

      // Print to stderr for debugging
      printToStderr("⚠️ UNEXPECTED ERROR: \(error)")
      printToStderr("  Type: \(type(of: error))")
      printToStderr("  Description: \(String(reflecting: error))")

      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 500,
        rawResponse: error.localizedDescription
      )
    }
  }

  /// Modify (create, update, delete) records
  @available(
    *, deprecated,
    message: "Use modifyRecords(_:) with RecordOperation in CloudKitService+WriteOperations instead"
  )
  internal func modifyRecords(
    operations: [Components.Schemas.RecordOperation],
    atomic: Bool = true
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      let response = try await client.modifyRecords(
        .init(
          path: createModifyRecordsPath(containerIdentifier: containerIdentifier),
          body: .json(
            .init(
              operations: operations,
              atomic: atomic
            )
          )
        )
      )

      let modifyData: Components.Schemas.ModifyResponse =
        try await responseProcessor.processModifyRecordsResponse(response)
      return modifyData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 500,
        rawResponse: error.localizedDescription
      )
    }
  }

  /// Lookup records by record names
  internal func lookupRecords(
    recordNames: [String],
    desiredKeys: [String]? = nil
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      let response = try await client.lookupRecords(
        .init(
          path: createLookupRecordsPath(containerIdentifier: containerIdentifier),
          body: .json(
            .init(
              records: recordNames.map { recordName in
                .init(
                  recordName: recordName,
                  desiredKeys: desiredKeys
                )
              }
            )
          )
        )
      )

      let lookupData: Components.Schemas.LookupResponse =
        try await responseProcessor.processLookupRecordsResponse(response)
      return lookupData.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      throw CloudKitError.httpErrorWithRawResponse(
        statusCode: 500,
        rawResponse: error.localizedDescription
      )
    }
  }
}
