//
//  CloudKitServiceTests.RecordWriteConvenience.swift
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
internal import Testing

@testable import MistKit

extension CloudKitServiceTests {
  /// Covers the single-record write conveniences (`createRecord`,
  /// `updateRecord`, `deleteRecord`) which delegate to `modifyRecords`.
  @Suite("Record Write Convenience")
  internal struct RecordWriteConvenience {
    /// Reuse the shared mock-transport builders and JSON record fixtures.
    private typealias Helper = CloudKitServiceTests.Rereference

    @Test("createRecord returns the saved record")
    internal func createReturnsRecord() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "modifyRecords": try Helper.recordsResponse([
          Helper.noteRecord(recordName: "note-1", changeTag: "tag-1")
        ])
      ])

      let record = try await service.createRecord(
        recordType: "Note",
        recordName: "note-1",
        fields: ["title": .string("Hello")],
        database: Helper.publicDatabase
      )

      #expect(record.recordName == "note-1")
    }

    @Test("createRecord throws invalidResponse when the server returns no records")
    internal func createThrowsOnEmptyResponse() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "modifyRecords": try Helper.recordsResponse([])
      ])

      await #expect(throws: CloudKitError.self) {
        _ = try await service.createRecord(
          recordType: "Note",
          fields: ["title": .string("Hello")],
          database: Helper.publicDatabase
        )
      }
    }

    @Test("updateRecord returns the saved record")
    internal func updateReturnsRecord() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "modifyRecords": try Helper.recordsResponse([
          Helper.noteRecord(recordName: "note-1", changeTag: "tag-2")
        ])
      ])

      let record = try await service.updateRecord(
        recordType: "Note",
        recordName: "note-1",
        fields: ["title": .string("Renamed")],
        recordChangeTag: "tag-1",
        database: Helper.publicDatabase
      )

      #expect(record.recordName == "note-1")
      #expect(record.recordChangeTag == "tag-2")
    }

    @Test("updateRecord throws invalidResponse when the server returns no records")
    internal func updateThrowsOnEmptyResponse() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let service = try Helper.makeService(responsesByOperation: [
        "modifyRecords": try Helper.recordsResponse([])
      ])

      await #expect(throws: CloudKitError.self) {
        _ = try await service.updateRecord(
          recordType: "Note",
          recordName: "note-1",
          fields: ["title": .string("Renamed")],
          database: Helper.publicDatabase
        )
      }
    }

    @Test("deleteRecord completes when the server acknowledges the delete")
    internal func deleteCompletes() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Helper.makeServiceWithProvider(responsesByOperation: [
        "modifyRecords": try Helper.recordsResponse([
          Helper.noteRecord(recordName: "note-1", changeTag: "tag-2")
        ])
      ])

      try await service.deleteRecord(
        recordType: "Note",
        recordName: "note-1",
        recordChangeTag: "tag-1",
        database: Helper.publicDatabase
      )

      #expect(await provider.callCount(for: "modifyRecords") == 1)
    }
  }
}
