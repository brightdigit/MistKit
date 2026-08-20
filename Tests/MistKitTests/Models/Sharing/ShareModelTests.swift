//
//  ShareModelTests.swift
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

@Suite("Sharing Models")
internal struct ShareModelTests {
  @Test("ShortGUID round-trips through Codable")
  internal func shortGUIDRoundTrips() throws {
    let original = ShortGUID(
      value: "guid-1",
      shouldFetchRootRecord: true,
      rootRecordDesiredKeys: ["title", "body"]
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ShortGUID.self, from: data)
    #expect(decoded == original)
  }

  @Test("ShortGUID defaults the optional knobs to nil")
  internal func shortGUIDDefaults() {
    let shortGUID = ShortGUID(value: "guid-1")
    #expect(shortGUID.value == "guid-1")
    #expect(shortGUID.shouldFetchRootRecord == nil)
    #expect(shortGUID.rootRecordDesiredKeys == nil)
  }

  @Test(
    "SharePermission maps CloudKit's wire values",
    arguments: [
      ("NONE", SharePermission.none),
      ("READ_ONLY", .readOnly),
      ("READ_WRITE", .readWrite),
      ("UNKNOWN", .unknown),
    ]
  )
  internal func sharePermissionRawValues(raw: String, expected: SharePermission) {
    #expect(SharePermission(rawValue: raw) == expected)
    #expect(expected.rawValue == raw)
  }

  @Test(
    "ShareParticipantType maps CloudKit's wire values",
    arguments: [
      ("OWNER", ShareParticipantType.owner),
      ("ADMINISTRATOR", .administrator),
      ("USER", .user),
      ("PUBLIC_USER", .publicUser),
      ("UNKNOWN", .unknown),
    ]
  )
  internal func participantTypeRawValues(raw: String, expected: ShareParticipantType) {
    #expect(ShareParticipantType(rawValue: raw) == expected)
    #expect(expected.rawValue == raw)
  }

  @Test(
    "ShareAcceptanceStatus maps CloudKit's wire values",
    arguments: [
      ("INVITED", ShareAcceptanceStatus.invited),
      ("ACCEPTED", .accepted),
      ("REMOVED", .removed),
      ("UNKNOWN", .unknown),
    ]
  )
  internal func acceptanceStatusRawValues(raw: String, expected: ShareAcceptanceStatus) {
    #expect(ShareAcceptanceStatus(rawValue: raw) == expected)
    #expect(expected.rawValue == raw)
  }

  @Test(
    "ShareDatabaseScope maps CloudKit's wire values",
    arguments: [
      ("PUBLIC", ShareDatabaseScope.public),
      ("PRIVATE", .private),
      ("SHARED", .shared),
    ]
  )
  internal func databaseScopeRawValues(raw: String, expected: ShareDatabaseScope) {
    #expect(ShareDatabaseScope(rawValue: raw) == expected)
    #expect(expected.rawValue == raw)
  }

  @Test("ShareRecordInfo defaults every field when constructed empty")
  internal func shareRecordInfoDefaults() {
    let info = ShareRecordInfo()
    #expect(info.shortGUID == nil)
    #expect(info.containerIdentifier == nil)
    #expect(info.databaseScope == nil)
    #expect(info.environment == nil)
    #expect(info.zoneID == nil)
    #expect(info.rootRecord == nil)
    #expect(info.share == nil)
    #expect(info.ownerIdentity == nil)
    #expect(info.participantPermission == nil)
    #expect(info.participantStatus == nil)
    #expect(info.participantType == nil)
    #expect(info.webpageURL == nil)
    #expect(info.potentialMatchList.isEmpty)
  }

  @Test("SharePotentialMatch carries partial contact information")
  internal func potentialMatchPartialContact() {
    let emailOnly = SharePotentialMatch(
      participantId: "c1",
      contactInformation: .init(emailAddress: "a@example.com")
    )
    #expect(emailOnly.contactInformation?.emailAddress == "a@example.com")
    #expect(emailOnly.contactInformation?.phoneNumber == nil)
  }

  @Test("ShareInfo defaults every field when constructed empty")
  internal func shareInfoDefaults() {
    let info = ShareInfo()
    #expect(info.shortGUID == nil)
    #expect(info.sharedRecordName == nil)
    #expect(info.publicPermission == nil)
    #expect(info.participants.isEmpty)
    #expect(info.owner == nil)
    #expect(info.currentUserParticipant == nil)
  }

  @Test("ShareParticipant defaults every field to nil")
  internal func shareParticipantDefaults() {
    let participant = ShareParticipant()
    #expect(participant.userIdentity == nil)
    #expect(participant.permission == nil)
    #expect(participant.type == nil)
    #expect(participant.acceptanceStatus == nil)
  }
}
