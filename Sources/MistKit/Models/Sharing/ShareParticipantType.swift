//
//  ShareParticipantType.swift
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

/// The kind of participant in a shared record.
public enum ShareParticipantType: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
  /// The owner of the shared record.
  case owner = "OWNER"
  /// A participant who may modify the participant list.
  case administrator = "ADMINISTRATOR"
  /// A participant invited by identity.
  case user = "USER"
  /// A participant who arrived through the share's public permission.
  case publicUser = "PUBLIC_USER"
  /// CloudKit did not report a known participant type.
  case unknown = "UNKNOWN"
}

// MARK: - Internal Conversion
extension ShareParticipantType {
  internal var asShareParticipantPayload: Components.Schemas.ShareParticipant._typePayload {
    switch self {
    case .owner: .OWNER
    case .administrator: .ADMINISTRATOR
    case .user: .USER
    case .publicUser: .PUBLIC_USER
    case .unknown: .UNKNOWN
    }
  }

  internal init(from payload: Components.Schemas.ShareParticipant._typePayload) {
    switch payload {
    case .OWNER: self = .owner
    case .ADMINISTRATOR: self = .administrator
    case .USER: self = .user
    case .PUBLIC_USER: self = .publicUser
    case .UNKNOWN: self = .unknown
    }
  }

  internal init(from payload: Components.Schemas.ShortGUIDResult.participantTypePayload) {
    switch payload {
    case .OWNER: self = .owner
    case .ADMINISTRATOR: self = .administrator
    case .USER: self = .user
    case .PUBLIC_USER: self = .publicUser
    case .UNKNOWN: self = .unknown
    }
  }
}
