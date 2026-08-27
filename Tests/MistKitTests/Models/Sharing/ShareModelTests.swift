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
  private static let owner = ShareParticipant(
    userIdentity: UserIdentity(userRecordName: .recordName("_owner")),
    permission: .readWrite,
    type: .owner,
    acceptanceStatus: .accepted
  )

  @Test("ShortGUIDDictionary round-trips through Codable")
  internal func shortGUIDDictionaryRoundTrips() throws {
    let original = ShortGUIDDictionary(
      value: "guid-1",
      shouldFetchRootRecord: true,
      rootRecordDesiredKeys: ["title", "body"]
    )
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ShortGUIDDictionary.self, from: data)
    #expect(decoded == original)
  }

  @Test("ShortGUIDDictionary defaults the optional knobs to nil")
  internal func shortGUIDDictionaryDefaults() {
    let shortGUID = ShortGUIDDictionary(value: "guid-1")
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

  @Test("ShareRecordInfo requires shortGUID and defaults the rest")
  internal func shareRecordInfoDefaults() {
    let info = ShareRecordInfo(shortGUID: ShortGUIDDictionary(value: "guid-1"))
    #expect(info.shortGUID.value == "guid-1")
    #expect(info.containerIdentifier == nil)
    #expect(info.databaseScope == nil)
    #expect(info.environment == nil)
    #expect(info.zoneID == nil)
    #expect(info.rootRecord == nil)
    #expect(info.share == nil)
    #expect(info.shareInfo == nil)
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
      contactInformation: ContactInformation(emailAddress: "a@example.com")
    )
    #expect(emailOnly.participantId == "c1")
    #expect(emailOnly.contactInformation?.emailAddress == "a@example.com")
    #expect(emailOnly.contactInformation?.phoneNumber == nil)
  }

  @Test("CreatedShare builds invite URLs from shareURLBase")
  internal func createdShareURLUsesBase() {
    let url = CreatedShare.shareURL(forShortGUID: "guid-1")
    #expect(url.absoluteString == "https://www.icloud.com/share/guid-1")
    #expect(url.absoluteString.hasPrefix(CreatedShare.shareURLBase.absoluteString))
  }

  @Test("UserIdentityLookupInfo Codable stays flat on the wire")
  internal func lookupInfoCodableIsFlat() throws {
    let original = UserIdentityLookupInfo(
      contactInformation: ContactInformation(
        emailAddress: "a@example.com",
        phoneNumber: "+15550100"
      ),
      userRecordName: "_user-1"
    )
    let data = try JSONEncoder().encode(original)
    let json = try #require(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    #expect(json["emailAddress"] as? String == "a@example.com")
    #expect(json["phoneNumber"] as? String == "+15550100")
    #expect(json["userRecordName"] as? String == "_user-1")
    #expect(json["contactInformation"] == nil)

    let decoded = try JSONDecoder().decode(UserIdentityLookupInfo.self, from: data)
    #expect(decoded.emailAddress == "a@example.com")
    #expect(decoded.phoneNumber == "+15550100")
    #expect(decoded.userRecordName == "_user-1")
    #expect(decoded.contactInformation?.emailAddress == "a@example.com")
  }

  @Test("ShareInfo requires the share key set")
  internal func shareInfoRequiresKeys() {
    let info = ShareInfo(
      shortGUID: "guid-1",
      publicPermission: .none,
      participants: [Self.owner],
      owner: Self.owner,
      currentUserParticipant: Self.owner
    )
    #expect(info.shortGUID == "guid-1")
    #expect(info.publicPermission == .none)
    #expect(info.participants.count == 1)
    #expect(info.owner.type == .owner)
    #expect(info.currentUserParticipant.type == .owner)
  }

  @Test("ShareParticipant requires identity, permission, type, and status")
  internal func shareParticipantRequiresFields() {
    let participant = ShareParticipant(
      userIdentity: UserIdentity(
        lookupInfo: UserIdentityLookupInfo(emailAddress: "a@example.com")
      ),
      permission: .readWrite,
      type: .user,
      acceptanceStatus: .invited
    )
    #expect(participant.userIdentity.userRecordName == .nonDiscoverable)
    #expect(participant.permission == .readWrite)
    #expect(participant.type == .user)
    #expect(participant.acceptanceStatus == .invited)
  }
}
