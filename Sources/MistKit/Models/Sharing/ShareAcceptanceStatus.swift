//
//  ShareAcceptanceStatus.swift
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

/// Whether a participant has accepted a shared record.
public enum ShareAcceptanceStatus: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
  /// The participant has been invited but has not yet accepted.
  case invited = "INVITED"
  /// The participant accepted the share.
  case accepted = "ACCEPTED"
  /// The participant was removed from the share.
  case removed = "REMOVED"
  /// CloudKit did not report a known acceptance status.
  case unknown = "UNKNOWN"
}

// MARK: - Internal Conversion
extension ShareAcceptanceStatus {
  internal init(from payload: Components.Schemas.ShareParticipant.acceptanceStatusPayload) {
    switch payload {
    case .INVITED: self = .invited
    case .ACCEPTED: self = .accepted
    case .REMOVED: self = .removed
    case .UNKNOWN: self = .unknown
    }
  }

  internal init(from payload: Components.Schemas.ShortGUIDResult.participantStatusPayload) {
    switch payload {
    case .INVITED: self = .invited
    case .ACCEPTED: self = .accepted
    case .REMOVED: self = .removed
    case .UNKNOWN: self = .unknown
    }
  }
}
