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
  import Foundation
  import MistKit

  @testable import MistDemoKit

  /// In-memory `WebDemoBackend` for routing-level tests. Records the last
  /// call to each operation and returns deterministic stub records.
  internal final actor MockBackend: WebDemoBackend {
    internal struct QueryCall: Sendable {
      let recordType: String
      let limit: Int?
    }

    internal struct CreateCall: Sendable {
      let recordType: String
      let fields: [String: String]
    }

    internal struct UpdateCall: Sendable {
      let recordType: String
      let recordName: String
      let fields: [String: String]
    }

    internal struct DeleteCall: Sendable {
      let recordType: String
      let recordName: String
    }

    private(set) var lastQuery: QueryCall?
    private(set) var lastCreate: CreateCall?
    private(set) var lastUpdate: UpdateCall?
    private(set) var lastDelete: DeleteCall?
    private var pendingError: String?

    internal func failNext(message: String) {
      pendingError = message
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
      // swiftlint:disable:next force_try
      return try! JSONDecoder().decode(
        RecordInfo.self, from: Data(json.utf8)
      )
    }

    internal func webDemoQuery(
      recordType: String, limit: Int?
    ) async throws -> [RecordInfo] {
      lastQuery = QueryCall(recordType: recordType, limit: limit)
      try consumePendingError()
      return [
        Self.stubRecord(recordType: recordType, recordName: "stub-1")
      ]
    }

    internal func webDemoCreate(
      recordType: String, fields: [String: FieldValue]
    ) async throws -> RecordInfo {
      lastCreate = CreateCall(
        recordType: recordType,
        fields: Self.flatten(fields)
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: "created-1"
      )
    }

    internal func webDemoUpdate(
      recordType: String,
      recordName: String,
      fields: [String: FieldValue]
    ) async throws -> RecordInfo {
      lastUpdate = UpdateCall(
        recordType: recordType,
        recordName: recordName,
        fields: Self.flatten(fields)
      )
      try consumePendingError()
      return Self.stubRecord(
        recordType: recordType, recordName: recordName
      )
    }

    internal func webDemoDelete(
      recordType: String, recordName: String
    ) async throws {
      lastDelete = DeleteCall(
        recordType: recordType, recordName: recordName
      )
      try consumePendingError()
    }

    /// Flatten FieldValue.string entries back to plain strings so tests
    /// can `#expect(captured.fields["title"] == "Hi")` without unwrapping.
    private static func flatten(
      _ fields: [String: FieldValue]
    ) -> [String: String] {
      var result: [String: String] = [:]
      for (name, value) in fields {
        if case .string(let string) = value {
          result[name] = string
        }
      }
      return result
    }
  }
#endif
