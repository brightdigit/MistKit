//
//  ShareParticipant.swift
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

/// A participant in a shared record.
///
/// Participants appear on `cloudKit.share` records — as the `participants`
/// list, the share's `owner`, and the caller's own `currentUserParticipant`
/// entry.
public struct ShareParticipant: Codable, Sendable {
  /// The identity of the participant, when CloudKit could resolve one.
  public let userIdentity: UserIdentity?
  /// The participant's read and write permissions.
  public let permission: SharePermission?
  /// The kind of participant.
  public let type: ShareParticipantType?
  /// Whether the participant has accepted the share.
  public let acceptanceStatus: ShareAcceptanceStatus?

  /// Initialize a share participant.
  /// - Parameters:
  ///   - userIdentity: The participant's identity.
  ///   - permission: The participant's read and write permissions.
  ///   - type: The kind of participant.
  ///   - acceptanceStatus: Whether the participant accepted the share.
  public init(
    userIdentity: UserIdentity? = nil,
    permission: SharePermission? = nil,
    type: ShareParticipantType? = nil,
    acceptanceStatus: ShareAcceptanceStatus? = nil
  ) {
    self.userIdentity = userIdentity
    self.permission = permission
    self.type = type
    self.acceptanceStatus = acceptanceStatus
  }

  internal init(from schema: Components.Schemas.ShareParticipant) {
    self.userIdentity = schema.userIdentity.map(UserIdentity.init(from:))
    self.permission = schema.permission.map(SharePermission.init(from:))
    self.type = schema._type.map(ShareParticipantType.init(from:))
    self.acceptanceStatus = schema.acceptanceStatus.map(ShareAcceptanceStatus.init(from:))
  }
}
