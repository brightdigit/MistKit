//
//  CloudKitServiceTests.RecordWriteConvenience+ZoneID.swift
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

extension CloudKitServiceTests.RecordWriteConvenience {
  /// Pins zoneID forwarding on the single-record write conveniences (#454).
  @Suite("Record Write Convenience ZoneID", .disabled(if: Platform.isWindowsSwift62))
  internal struct ZoneIDForwarding {
    private typealias Helper = CloudKitServiceTests.Rereference

    @Test("createRecord forwards zoneID into the modifyRecords request body")
    internal func createForwardsZoneID() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
          Issue.record("CloudKitService is not available on this operating system.")
          return
        }
        let (service, provider) = try Helper.makeServiceWithProvider(responsesByOperation: [
          "modifyRecords": try Helper.recordsResponse([
            Helper.noteRecord(recordName: "note-1", changeTag: "tag-1")
          ])
        ])

        _ = try await service.createRecord(
          recordType: "Note",
          recordName: "note-1",
          fields: ["title": .string("Hello")],
          zoneID: ZoneID(zoneName: "Articles", ownerName: "_abc123"),
          database: Helper.publicDatabase
        )

        let bodies = await provider.bodies(for: "modifyRecords").compactMap { $0 }
        let data = try #require(bodies.first)
        let body = try #require(
          try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let zoneID = try #require(body["zoneID"] as? [String: Any])
        #expect(zoneID["zoneName"] as? String == "Articles")
        #expect(zoneID["ownerRecordName"] as? String == "_abc123")
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("updateRecord forwards zoneID into the modifyRecords request body")
    internal func updateForwardsZoneID() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
          Issue.record("CloudKitService is not available on this operating system.")
          return
        }
        let (service, provider) = try Helper.makeServiceWithProvider(responsesByOperation: [
          "modifyRecords": try Helper.recordsResponse([
            Helper.noteRecord(recordName: "note-1", changeTag: "tag-2")
          ])
        ])

        _ = try await service.updateRecord(
          recordType: "Note",
          recordName: "note-1",
          fields: ["title": .string("Renamed")],
          recordChangeTag: "tag-1",
          zoneID: ZoneID(zoneName: "Articles", ownerName: "_abc123"),
          database: Helper.publicDatabase
        )

        let bodies = await provider.bodies(for: "modifyRecords").compactMap { $0 }
        let data = try #require(bodies.first)
        let body = try #require(
          try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let zoneID = try #require(body["zoneID"] as? [String: Any])
        #expect(zoneID["zoneName"] as? String == "Articles")
        #expect(zoneID["ownerRecordName"] as? String == "_abc123")
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("deleteRecord forwards zoneID into the modifyRecords request body")
    internal func deleteForwardsZoneID() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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
          zoneID: ZoneID(zoneName: "Articles", ownerName: "_abc123"),
          database: Helper.publicDatabase
        )

        let bodies = await provider.bodies(for: "modifyRecords").compactMap { $0 }
        let data = try #require(bodies.first)
        let body = try #require(
          try JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        let zoneID = try #require(body["zoneID"] as? [String: Any])
        #expect(zoneID["zoneName"] as? String == "Articles")
        #expect(zoneID["ownerRecordName"] as? String == "_abc123")
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }
  }
}
