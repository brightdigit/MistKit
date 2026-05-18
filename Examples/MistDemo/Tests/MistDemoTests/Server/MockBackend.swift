//
//  MockBackend.swift
//  MistDemoTests
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import MistKit

  @testable import MistDemoKit

  /// In-memory `WebBackend` for routing-level tests. Records the last
  /// call to each operation and returns deterministic stub records.
  internal final actor MockBackend: WebBackend {
    internal struct QueryCall: Sendable {
      internal let recordType: String
      internal let limit: Int?
      internal let sortBy: [WebRequests.QuerySortField]?
      internal let database: MistKit.Database
    }

    internal struct CreateCall: Sendable {
      internal let recordType: String
      internal let fields: [String: String]
      internal let database: MistKit.Database
    }

    internal struct UpdateCall: Sendable {
      internal let recordType: String
      internal let recordName: String
      internal let fields: [String: String]
      internal let recordChangeTag: String?
      internal let database: MistKit.Database
    }

    internal struct DeleteCall: Sendable {
      internal let recordType: String
      internal let recordName: String
      internal let recordChangeTag: String?
      internal let database: MistKit.Database
    }

    internal private(set) var lastQuery: QueryCall?
    internal private(set) var lastCreate: CreateCall?
    internal private(set) var lastUpdate: UpdateCall?
    internal private(set) var lastDelete: DeleteCall?
    private var pendingError: String?

    private static func stubRecord(
      recordType: String, recordName: String
    ) -> RecordInfo {
      let json = """
        {
          "recordName": "\(recordName)",
          "recordType": "\(recordType)",
          "recordChangeTag": null,
          "fields": {},
          "created": null,
          "modified": null,
          "deleted": false
        }
        """
      // RecordInfo is Codable; round-trip through JSON keeps the stub
      // independent of MistKit's internal initializer.
      do {
        return try JSONDecoder().decode(
          RecordInfo.self, from: Data(json.utf8)
        )
      } catch {
        fatalError("MockBackend stubRecord JSON failed to decode: \(error)")
      }
    }

    /// Flatten FieldValue entries into a printable form so tests can write
    /// `#expect(captured.fields["title"] == "Hi")` for strings or
    /// `#expect(captured.fields["index"] == "5")` for numbers without
    /// pattern-matching on FieldValue in every assertion.
    ///
    /// Non-primitive cases (asset, date, reference, location, list, bytes)
    /// are intentionally dropped — they yield no useful String form for an
    /// equality assertion. Tests that need to assert those types should
    /// inspect the FieldValue directly rather than going through `flatten`.
    private static func flatten(
      _ fields: [String: FieldValue]
    ) -> [String: String] {
      var result: [String: String] = [:]
      for (name, value) in fields {
        switch value {
        case .string(let string):
          result[name] = string
        case .int64(let int):
          result[name] = String(int)
        case .double(let double):
          result[name] = String(double)
        default:
          continue
        }
      }
      return result
    }

    internal func failNext(message: String) {
      pendingError = message
    }

    internal func webQuery(
      recordType: String,
      limit: Int?,
      sortBy: [WebRequests.QuerySortField]?,
      database: MistKit.Database
    ) async throws -> [RecordInfo] {
      lastQuery = QueryCall(
        recordType: recordType,
        limit: limit,
        sortBy: sortBy,
        database: database
      )
      try consumePendingError()
      return [
        Self.stubRecord(recordType: recordType, recordName: "stub-1")
      ]
    }

    internal func webCreate(
      recordType: String,
      fields: [String: FieldValue],
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastCreate = CreateCall(
        recordType: recordType,
        fields: Self.flatten(fields),
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: "created-1"
      )
    }

    internal func webUpdate(
      recordType: String,
      recordName: String,
      fields: [String: FieldValue],
      recordChangeTag: String?,
      database: MistKit.Database
    ) async throws -> RecordInfo {
      lastUpdate = UpdateCall(
        recordType: recordType,
        recordName: recordName,
        fields: Self.flatten(fields),
        recordChangeTag: recordChangeTag,
        database: database
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: recordName
      )
    }

    internal func webDelete(
      recordType: String,
      recordName: String,
      recordChangeTag: String?,
      database: MistKit.Database
    ) async throws {
      lastDelete = DeleteCall(
        recordType: recordType,
        recordName: recordName,
        recordChangeTag: recordChangeTag,
        database: database
      )
      try consumePendingError()
    }

    private func consumePendingError() throws {
      if let message = pendingError {
        pendingError = nil
        struct StubError: LocalizedError {
          let errorDescription: String?
        }
        throw StubError(errorDescription: message)
      }
    }
  }
#endif
