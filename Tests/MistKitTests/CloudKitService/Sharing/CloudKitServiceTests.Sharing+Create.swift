//
//  CloudKitServiceTests.Sharing+Create.swift
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

extension CloudKitServiceTests.Sharing {
  @Suite(
    "CloudKitService createShare",
    .enabled(if: Platform.isCryptoAvailable)
  )
  internal struct Create {
    private typealias Helper = CloudKitServiceTests.Sharing

    private static let zoneID = ZoneID(zoneName: "ShareZone")
    private static let sharee = ShareParticipant(
      userIdentity: UserIdentity(
        lookupInfo: UserIdentityLookupInfo(emailAddress: "sharee@example.com")
      ),
      permission: .readWrite,
      type: .user,
      acceptanceStatus: .invited
    )

    private static func expectRootCreateBody(_ body: Data) throws {
      let rootJSON = try #require(
        try JSONSerialization.jsonObject(with: body) as? [String: Any]
      )
      #expect(rootJSON["atomic"] as? Bool == false)
      let rootZone = try #require(rootJSON["zoneID"] as? [String: Any])
      #expect(rootZone["zoneName"] as? String == "ShareZone")
      let rootOps = try #require(rootJSON["operations"] as? [[String: Any]])
      #expect(rootOps.count == 1)
      let rootRecord = try #require(rootOps[0]["record"] as? [String: Any])
      #expect(rootRecord["createShortGUID"] as? Bool == true)
      #expect(rootRecord["recordType"] as? String == "Note")
      #expect(rootRecord["recordName"] as? String == "root-1")
      #expect(rootRecord["forRecord"] == nil)
    }

    private static func expectShareCreateBody(_ body: Data) throws {
      let shareJSON = try #require(
        try JSONSerialization.jsonObject(with: body) as? [String: Any]
      )
      #expect(shareJSON["atomic"] as? Bool == true)
      let shareOps = try #require(shareJSON["operations"] as? [[String: Any]])
      #expect(shareOps.count == 1)
      let shareRecord = try #require(shareOps[0]["record"] as? [String: Any])
      #expect(shareRecord["recordType"] as? String == ShareInfo.recordType)
      #expect(shareRecord["publicPermission"] as? String == "NONE")
      let forRecord = try #require(shareRecord["forRecord"] as? [String: Any])
      #expect(forRecord["recordName"] as? String == "root-1")
      #expect(forRecord["recordChangeTag"] as? String == "tag-1")
      let participants = try #require(shareRecord["participants"] as? [[String: Any]])
      #expect(participants.count == 1)
      #expect(participants[0]["permission"] as? String == "READ_WRITE")
      #expect(participants[0]["type"] as? String == "USER")
      #expect(participants[0]["acceptanceStatus"] as? String == "INVITED")
      let identity = try #require(participants[0]["userIdentity"] as? [String: Any])
      let lookup = try #require(identity["lookupInfo"] as? [String: Any])
      #expect(lookup["emailAddress"] as? String == "sharee@example.com")
      #expect(shareRecord["createShortGUID"] == nil)
    }

    @Test("createShare returns shortGUID, share URL, and root record")
    internal func createShareMapsResult() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Helper.makeServiceWithProvider(
        responsesByOperation: [:]
      )
      await provider.enqueue(
        try Helper.recordsResponse([Helper.shareableRootRecord()]),
        for: "modifyRecords"
      )
      await provider.enqueue(
        try Helper.recordsResponse([Helper.createdShareRecord()]),
        for: "modifyRecords"
      )

      let created = try await service.createShare(
        rootRecordType: "Note",
        rootRecordName: "root-1",
        rootFields: ["title": .string("Shared Note")],
        zoneID: Self.zoneID,
        participants: [Self.sharee],
        database: .private
      )

      #expect(created.shortGUID == "guid-share-1")
      #expect(created.shareURL.absoluteString == "https://www.icloud.com/share/guid-share-1")
      #expect(created.rootRecord.recordName == "root-1")
      #expect(created.rootRecord.recordType == "Note")
      #expect(created.shareRecordName == "share-1")
      #expect(created.share.shortGUID == "guid-share-1")
      #expect(created.share.publicPermission == SharePermission.none)
      #expect(created.share.participants.count == 2)
      #expect(created.share.owner.type == .owner)
      #expect(created.share.currentUserParticipant.type == .owner)
    }

    @Test("createShare creates root then atomic cloudkit.share with change tag")
    internal func createShareSerializesShareCreateBody() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      let (service, provider) = try Helper.makeServiceWithProvider(
        responsesByOperation: [:]
      )
      await provider.enqueue(
        try Helper.recordsResponse([Helper.shareableRootRecord(changeTag: "tag-1")]),
        for: "modifyRecords"
      )
      await provider.enqueue(
        try Helper.recordsResponse([Helper.createdShareRecord()]),
        for: "modifyRecords"
      )

      _ = try await service.createShare(
        rootRecordType: "Note",
        rootRecordName: "root-1",
        rootFields: ["title": .string("Shared Note")],
        zoneID: Self.zoneID,
        publicPermission: .none,
        participants: [Self.sharee],
        database: .private
      )

      let bodies = await provider.bodies(for: "modifyRecords").compactMap { $0 }
      #expect(bodies.count == 2)
      try Self.expectRootCreateBody(bodies[0])
      try Self.expectShareCreateBody(bodies[1])
    }

    @Test("createShare throws when the share response is incomplete")
    internal func createShareRequiresCompleteShareInfo() async throws {
      guard #available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *) else {
        Issue.record("CloudKitService is not available on this operating system.")
        return
      }
      var shareWithoutGUID = Helper.createdShareRecord()
      shareWithoutGUID.removeValue(forKey: "shortGUID")
      var rootWithoutGUID = Helper.shareableRootRecord()
      rootWithoutGUID.removeValue(forKey: "shortGUID")
      let (service, provider) = try Helper.makeServiceWithProvider(
        responsesByOperation: [:]
      )
      await provider.enqueue(
        try Helper.recordsResponse([rootWithoutGUID]),
        for: "modifyRecords"
      )
      await provider.enqueue(
        try Helper.recordsResponse([shareWithoutGUID]),
        for: "modifyRecords"
      )

      await ConversionFailureReporter.$assertionHandler.withValue(
        { _, _, _ in },
        operation: {
          await #expect(throws: CloudKitError.self) {
            _ = try await service.createShare(
              rootRecordType: "Note",
              rootRecordName: "root-1",
              zoneID: Self.zoneID,
              participants: [Self.sharee],
              database: .private
            )
          }
        }
      )
    }
  }
}
