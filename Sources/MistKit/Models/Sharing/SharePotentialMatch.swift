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

extension [SharePotentialMatch] {
  /// Lift a potential-match list from the wire schema.
  ///
  /// - Parameter schemas: The optional wire list (treated as empty when `nil`).
  /// - Throws: ``ConversionError/sharePotentialMatchMissingParticipantId`` when
  ///   any entry omits `participantId`.
  internal init(
    from schemas: Components.Schemas.ShortGUIDResult.potentialMatchListPayload?
  ) throws(ConversionError) {
    let wireMatches = schemas ?? []
    var matches: [SharePotentialMatch] = []
    for matchSchema in wireMatches {
      guard let match = SharePotentialMatch(from: matchSchema) else {
        try ConversionError.sharePotentialMatchMissingParticipantId.reportAndThrow()
      }
      matches.append(match)
    }
    self = matches
  }
}
