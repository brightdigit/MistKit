//
//  SharePotentialMatch.swift
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

/// A candidate participant offered when CloudKit cannot identify the caller
/// against exactly one invited participant.
///
/// When ``ShareRecordInfo/potentialMatchList`` is non-empty the user must
/// choose which invitation they are claiming before the share can be accepted.
/// ``participantId`` is required — without it there is nothing to claim.
public struct SharePotentialMatch: Codable, Sendable, Equatable, Hashable {
  /// Contact details CloudKit holds for a potential participant.
  public struct ContactInformation: Codable, Sendable, Equatable, Hashable {
    /// The candidate's email address, when known.
    public let emailAddress: String?
    /// The candidate's phone number, when known.
    public let phoneNumber: String?

    /// Initialize contact information.
    /// - Parameters:
    ///   - emailAddress: The candidate's email address.
    ///   - phoneNumber: The candidate's phone number.
    public init(emailAddress: String? = nil, phoneNumber: String? = nil) {
      self.emailAddress = emailAddress
      self.phoneNumber = phoneNumber
    }
  }

  /// The identifier to send back when claiming this invitation.
  public let participantId: String
  /// Contact details CloudKit holds for this candidate.
  public let contactInformation: ContactInformation?

  /// Initialize a potential match.
  /// - Parameters:
  ///   - participantId: The identifier of the candidate participant.
  ///   - contactInformation: Contact details for the candidate.
  public init(participantId: String, contactInformation: ContactInformation? = nil) {
    self.participantId = participantId
    self.contactInformation = contactInformation
  }

  /// Lift a potential match from the wire schema, or return `nil` when
  /// `participantId` is missing.
  internal init?(from schema: Components.Schemas.ShortGUIDResult.potentialMatchListPayloadPayload) {
    guard let participantId = schema.participantId else {
      return nil
    }
    self.participantId = participantId
    self.contactInformation = schema.contactInformation.map {
      ContactInformation(emailAddress: $0.emailAddress, phoneNumber: $0.phoneNumber)
    }
  }
}
