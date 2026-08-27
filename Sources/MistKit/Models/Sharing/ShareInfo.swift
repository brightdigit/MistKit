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

/// The share-specific keys carried by a `cloudkit.share` record.
///
/// CloudKit returns these alongside the ordinary Record Dictionary keys on
/// share records. They are lifted out here because ``RecordInfo`` models a
/// plain record and intentionally carries no sharing metadata.
///
/// A successful lift requires `shortGUID`, `publicPermission`, `owner`,
/// `currentUserParticipant`, and a fully convertible `participants` list.
/// Records with none of the share keys return `nil` from `init?(from:)`
/// (plain records). Records that look like shares but omit a required key
/// also return `nil` — callers that already have a share record should treat
/// that as ``ConversionError/shareIncomplete``.
public struct ShareInfo: Codable, Sendable {
  /// Wire `recordType` for share records (`cloudkit.share`).
  ///
  /// Apple's archived CloudKit Web Services docs write `cloudKit.share`, but
  /// the live API only accepts / returns the lowercase-`k` form. Using the
  /// camelCase spelling yields "Cannot share - no such record exists to
  /// share".
  public static let recordType = "cloudkit.share"

  /// The short GUID identifying this share.
  public let shortGUID: ShortGUID
  /// The public's read and write permissions on the shared record.
  public let publicPermission: SharePermission
  /// The participants in the share.
  public let participants: [ShareParticipant]
  /// The owner of the shared record.
  public let owner: ShareParticipant
  /// The current user's participation in the share.
  public let currentUserParticipant: ShareParticipant

  /// Initialize share information.
  /// - Parameters:
  ///   - shortGUID: The short GUID identifying this share.
  ///   - publicPermission: The public's permissions on the shared record.
  ///   - participants: The participants in the share.
  ///   - owner: The owner of the shared record.
  ///   - currentUserParticipant: The current user's participation.
  public init(
    shortGUID: ShortGUID,
    publicPermission: SharePermission,
    participants: [ShareParticipant] = [],
    owner: ShareParticipant,
    currentUserParticipant: ShareParticipant
  ) {
    self.shortGUID = shortGUID
    self.publicPermission = publicPermission
    self.participants = participants
    self.owner = owner
    self.currentUserParticipant = currentUserParticipant
  }

  /// Lift the share-specific keys out of a record response, or return `nil`
  /// when the record is not a share / is an incomplete share.
  internal init?(from record: Components.Schemas.RecordResponse) {
    let hasShareKeys =
      record.shortGUID != nil || record.share != nil || record.publicPermission != nil
      || record.participants != nil || record.owner != nil
      || record.currentUserParticipant != nil
    guard hasShareKeys else {
      return nil
    }

    guard let shortGUID = record.shortGUID,
      let publicPermission = record.publicPermission.map(SharePermission.init(from:)),
      let ownerSchema = record.owner,
      let owner = ShareParticipant(from: ownerSchema),
      let currentSchema = record.currentUserParticipant,
      let currentUserParticipant = ShareParticipant(from: currentSchema)
    else {
      return nil
    }

    let wireParticipants = record.participants ?? []
    var participants: [ShareParticipant] = []
    participants.reserveCapacity(wireParticipants.count)
    for schema in wireParticipants {
      guard let participant = ShareParticipant(from: schema) else {
        return nil
      }
      participants.append(participant)
    }

    self.shortGUID = shortGUID
    self.publicPermission = publicPermission
    self.participants = participants
    self.owner = owner
    self.currentUserParticipant = currentUserParticipant
  }
}
