//
//  ShareRecordInfo.swift
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

internal import MistKitOpenAPI

/// Information about a shared record, returned by `records/resolve` and
/// `records/accept`.
///
/// One `ShareRecordInfo` is produced per requested ``ShortGUID``, in request
/// order. Every field is optional because CloudKit populates the result
/// differently depending on the operation and on whether the caller asked for
/// the root record (``ShortGUID/shouldFetchRootRecord``).
///
/// When ``potentialMatchList`` is non-empty CloudKit could not identify the
/// caller against a single invited participant; the user must pick which
/// invitation they are claiming before the share can be accepted.
public struct ShareRecordInfo: Codable, Sendable {
  /// The short GUID this result was resolved from.
  public let shortGUID: ShortGUID?
  /// The container holding the shared record.
  public let containerIdentifier: String?
  /// The database scope holding the shared record.
  public let databaseScope: ShareDatabaseScope?
  /// The container environment holding the shared record.
  public let environment: Environment?
  /// The zone holding the shared record.
  public let zoneID: ZoneID?
  /// The name of the root record that was shared.
  public let rootRecordName: String?
  /// The shared root record, when ``ShortGUID/shouldFetchRootRecord`` asked
  /// for it.
  public let rootRecord: RecordInfo?
  /// The `cloudKit.share` record governing the share.
  public let share: RecordInfo?
  /// The share-specific keys lifted out of ``share`` — participants, the
  /// owner, the public permission, and the caller's own participation.
  public let shareInfo: ShareInfo?
  /// The identity of the share's owner.
  public let ownerIdentity: UserIdentity?
  /// The caller's read and write permissions on the share.
  public let participantPermission: SharePermission?
  /// The caller's acceptance status for the share.
  public let participantStatus: ShareAcceptanceStatus?
  /// The caller's participant type for the share.
  public let participantType: ShareParticipantType?
  /// The fallback webpage configured in CloudKit Dashboard, used to direct
  /// users somewhere when the operation fails.
  public let webpageURL: String?
  /// Candidate participants to choose from when the caller could not be
  /// matched to exactly one invitation.
  public let potentialMatchList: [SharePotentialMatch]

  internal init(from schema: Components.Schemas.ShortGUIDResult) throws(ConversionError) {
    self.shortGUID = schema.shortGUID.map(ShortGUID.init(from:))
    self.containerIdentifier = schema.containerIdentifier
    self.databaseScope = schema.databaseScope.map(ShareDatabaseScope.init(from:))
    self.environment = schema.environment.map {
      switch $0 {
      case .development: Environment.development
      case .production: Environment.production
      }
    }
    self.zoneID = schema.zoneID.map {
      ZoneID(zoneName: $0.zoneName ?? ZoneID.defaultZone.zoneName, ownerName: $0.ownerName)
    }
    self.rootRecordName = schema.rootRecordName
    if let rootRecord = schema.rootRecord {
      self.rootRecord = try RecordInfo(from: rootRecord)
    } else {
      self.rootRecord = nil
    }
    if let share = schema.share {
      self.share = try RecordInfo(from: share)
      self.shareInfo = ShareInfo(from: share)
    } else {
      self.share = nil
      self.shareInfo = nil
    }
    self.ownerIdentity = schema.ownerIdentity.map(UserIdentity.init(from:))
    self.participantPermission = schema.participantPermission.map(SharePermission.init(from:))
    self.participantStatus = schema.participantStatus.map(ShareAcceptanceStatus.init(from:))
    self.participantType = schema.participantType.map(ShareParticipantType.init(from:))
    self.webpageURL = schema.webpageURL
    self.potentialMatchList =
      schema.potentialMatchList?.map(SharePotentialMatch.init(from:)) ?? []
  }

  /// Initialize share record information.
  ///
  /// Primarily intended for testing and for constructing values manually
  /// rather than receiving them from CloudKit responses.
  ///
  /// - Parameters:
  ///   - shortGUID: The short GUID this result was resolved from.
  ///   - containerIdentifier: The container holding the shared record.
  ///   - databaseScope: The database scope holding the shared record.
  ///   - environment: The container environment holding the shared record.
  ///   - zoneID: The zone holding the shared record.
  ///   - rootRecordName: The name of the shared root record.
  ///   - rootRecord: The shared root record.
  ///   - share: The `cloudKit.share` record governing the share.
  ///   - shareInfo: The share-specific keys lifted out of `share`.
  ///   - ownerIdentity: The identity of the share's owner.
  ///   - participantPermission: The caller's permissions on the share.
  ///   - participantStatus: The caller's acceptance status.
  ///   - participantType: The caller's participant type.
  ///   - webpageURL: The dashboard-configured fallback webpage.
  ///   - potentialMatchList: Candidate participants to disambiguate the caller.
  public init(
    shortGUID: ShortGUID? = nil,
    containerIdentifier: String? = nil,
    databaseScope: ShareDatabaseScope? = nil,
    environment: Environment? = nil,
    zoneID: ZoneID? = nil,
    rootRecordName: String? = nil,
    rootRecord: RecordInfo? = nil,
    share: RecordInfo? = nil,
    shareInfo: ShareInfo? = nil,
    ownerIdentity: UserIdentity? = nil,
    participantPermission: SharePermission? = nil,
    participantStatus: ShareAcceptanceStatus? = nil,
    participantType: ShareParticipantType? = nil,
    webpageURL: String? = nil,
    potentialMatchList: [SharePotentialMatch] = []
  ) {
    self.shortGUID = shortGUID
    self.containerIdentifier = containerIdentifier
    self.databaseScope = databaseScope
    self.environment = environment
    self.zoneID = zoneID
    self.rootRecordName = rootRecordName
    self.rootRecord = rootRecord
    self.share = share
    self.shareInfo = shareInfo
    self.ownerIdentity = ownerIdentity
    self.participantPermission = participantPermission
    self.participantStatus = participantStatus
    self.participantType = participantType
    self.webpageURL = webpageURL
    self.potentialMatchList = potentialMatchList
  }
}
