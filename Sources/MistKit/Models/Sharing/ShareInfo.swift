//
//  ShareInfo.swift
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

/// The share-specific keys carried by a `cloudKit.share` record.
///
/// CloudKit returns these alongside the ordinary Record Dictionary keys on
/// share records. They are lifted out here because ``RecordInfo`` models a
/// plain record and intentionally carries no sharing metadata.
public struct ShareInfo: Codable, Sendable {
  /// The short GUID identifying this share.
  public let shortGUID: String?
  /// The record name of the shared record this share governs.
  public let sharedRecordName: String?
  /// The public's read and write permissions on the shared record.
  public let publicPermission: SharePermission?
  /// The participants in the share.
  public let participants: [ShareParticipant]
  /// The owner of the shared record.
  public let owner: ShareParticipant?
  /// The current user's participation in the share.
  public let currentUserParticipant: ShareParticipant?

  /// Initialize share information.
  /// - Parameters:
  ///   - shortGUID: The short GUID identifying this share.
  ///   - sharedRecordName: The record name of the shared record.
  ///   - publicPermission: The public's permissions on the shared record.
  ///   - participants: The participants in the share.
  ///   - owner: The owner of the shared record.
  ///   - currentUserParticipant: The current user's participation.
  public init(
    shortGUID: String? = nil,
    sharedRecordName: String? = nil,
    publicPermission: SharePermission? = nil,
    participants: [ShareParticipant] = [],
    owner: ShareParticipant? = nil,
    currentUserParticipant: ShareParticipant? = nil
  ) {
    self.shortGUID = shortGUID
    self.sharedRecordName = sharedRecordName
    self.publicPermission = publicPermission
    self.participants = participants
    self.owner = owner
    self.currentUserParticipant = currentUserParticipant
  }

  /// Lift the share-specific keys out of a record response, or return `nil`
  /// when the record carries none of them (i.e. it is not a share record).
  internal init?(from record: Components.Schemas.RecordResponse) {
    let hasShareKeys =
      record.shortGUID != nil || record.share != nil || record.publicPermission != nil
      || record.participants != nil || record.owner != nil
      || record.currentUserParticipant != nil
    guard hasShareKeys else {
      return nil
    }
    self.shortGUID = record.shortGUID
    self.sharedRecordName = record.share?.recordName
    self.publicPermission = record.publicPermission.map(SharePermission.init(from:))
    self.participants = record.participants?.map(ShareParticipant.init(from:)) ?? []
    self.owner = record.owner.map(ShareParticipant.init(from:))
    self.currentUserParticipant = record.currentUserParticipant.map(ShareParticipant.init(from:))
  }
}
