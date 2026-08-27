//
//  SharePermission.swift
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

/// A participant's — or the public's — read and write permissions on a
/// shared record.
public enum SharePermission: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
  /// No access.
  case none = "NONE"
  /// Read-only access.
  case readOnly = "READ_ONLY"
  /// Read and write access.
  case readWrite = "READ_WRITE"
  /// CloudKit did not report a known permission.
  case unknown = "UNKNOWN"
}

// MARK: - Internal Conversion
extension SharePermission {
  internal init(from payload: Components.Schemas.ShareParticipant.permissionPayload) {
    switch payload {
    case .NONE: self = .none
    case .READ_ONLY: self = .readOnly
    case .READ_WRITE: self = .readWrite
    case .UNKNOWN: self = .unknown
    }
  }

  internal init(from payload: Components.Schemas.ShortGUIDResult.participantPermissionPayload) {
    switch payload {
    case .NONE: self = .none
    case .READ_ONLY: self = .readOnly
    case .READ_WRITE: self = .readWrite
    case .UNKNOWN: self = .unknown
    }
  }

  internal init(from payload: Components.Schemas.RecordResponse.publicPermissionPayload) {
    switch payload {
    case .NONE: self = .none
    case .READ_ONLY: self = .readOnly
    case .READ_WRITE: self = .readWrite
    case .UNKNOWN: self = .unknown
    }
  }

  internal var asShareParticipantPayload: Components.Schemas.ShareParticipant.permissionPayload {
    switch self {
    case .none: .NONE
    case .readOnly: .READ_ONLY
    case .readWrite: .READ_WRITE
    case .unknown: .UNKNOWN
    }
  }

  internal var asRecordRequestPublicPermissionPayload:
    Components.Schemas.RecordRequest.publicPermissionPayload
  {
    switch self {
    case .none: .NONE
    case .readOnly: .READ_ONLY
    case .readWrite: .READ_WRITE
    case .unknown: .UNKNOWN
    }
  }
}

extension Components.Schemas.RecordRequest.publicPermissionPayload {
  internal init(from permission: SharePermission) {
    self = permission.asRecordRequestPublicPermissionPayload
  }
}
