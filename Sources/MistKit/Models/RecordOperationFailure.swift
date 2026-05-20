//
//  RecordOperationFailure.swift
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

/// A per-record failure returned inline in a CloudKit `modifyRecords` or
/// `lookupRecords` response.
///
/// CloudKit reports per-operation failures as error entries within the
/// otherwise-successful (HTTP 200) `records` array, carrying the failed
/// record's name, a server error code, and optional retry/redirect hints.
///
/// This is a data payload describing a failure, **not** a Swift `Error` type;
/// it is surfaced via ``RecordResult/failure(_:)`` from `modifyRecords` /
/// `lookupRecords`, and wrapped in ``CloudKitError/recordOperationFailed(_:)``
/// (which *is* an `Error`) when a single-record convenience
/// (`createRecord`/`updateRecord`/`deleteRecord`) hits one.
///
/// `RecordOperationFailure` is a MistKit-owned value, so callers can inspect a
/// failure with only `import MistKit` — no need to import the generated
/// `MistKitOpenAPI` module.
public struct RecordOperationFailure: Codable, Hashable, Sendable {
  /// The CloudKit server error code for a per-record failure.
  ///
  /// Mirrors CloudKit's documented `serverErrorCode` values; an
  /// ``unknown(_:)`` case carries any code not yet known to this version of
  /// MistKit so forward-compatibility never drops information.
  public enum ServerErrorCode: Codable, Hashable, Sendable {
    case accessDenied
    case atomicError
    case authenticationFailed
    case authenticationRequired
    case badRequest
    case conflict
    case exists
    case internalError
    case notFound
    case quotaExceeded
    case throttled
    case tryAgainLater
    case validatingReferenceError
    case zoneNotFound
    /// A server error code not recognized by this version of MistKit.
    case unknown(String)

    /// The known (case, raw CloudKit string) pairs — the single source of truth
    /// for converting in both directions.
    private static let knownPairs: [(code: ServerErrorCode, raw: String)] = [
      (.accessDenied, "ACCESS_DENIED"),
      (.atomicError, "ATOMIC_ERROR"),
      (.authenticationFailed, "AUTHENTICATION_FAILED"),
      (.authenticationRequired, "AUTHENTICATION_REQUIRED"),
      (.badRequest, "BAD_REQUEST"),
      (.conflict, "CONFLICT"),
      (.exists, "EXISTS"),
      (.internalError, "INTERNAL_ERROR"),
      (.notFound, "NOT_FOUND"),
      (.quotaExceeded, "QUOTA_EXCEEDED"),
      (.throttled, "THROTTLED"),
      (.tryAgainLater, "TRY_AGAIN_LATER"),
      (.validatingReferenceError, "VALIDATING_REFERENCE_ERROR"),
      (.zoneNotFound, "ZONE_NOT_FOUND"),
    ]

    /// The raw CloudKit string for this code (e.g. `"NOT_FOUND"`).
    public var rawValue: String {
      if case .unknown(let raw) = self {
        return raw
      }
      return Self.knownPairs.first { $0.code == self }?.raw ?? ""
    }

    /// Maps a raw CloudKit string to a known case, or ``unknown(_:)``.
    public init(rawValue: String) {
      self = Self.knownPairs.first { $0.raw == rawValue }?.code ?? .unknown(rawValue)
    }

    /// Decodes the code from its raw CloudKit string value.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.singleValueContainer()
      self.init(rawValue: try container.decode(String.self))
    }

    /// Encodes the code as its raw CloudKit string value.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }

  /// The name of the record the operation failed on.
  public let recordName: String
  /// The CloudKit server error code for the failure.
  public let serverErrorCode: ServerErrorCode
  /// A human-readable reason for the failure, if provided.
  public let reason: String?
  /// Suggested seconds to wait before retrying. Absent if not retryable.
  public let retryAfter: Int?
  /// A unique identifier for this error.
  public let uuid: String?
  /// Redirect URL for sign-in; present when `serverErrorCode` is
  /// ``ServerErrorCode/authenticationRequired``.
  public let redirectURL: String?

  /// Creates a per-record failure value.
  public init(
    recordName: String,
    serverErrorCode: ServerErrorCode,
    reason: String? = nil,
    retryAfter: Int? = nil,
    uuid: String? = nil,
    redirectURL: String? = nil
  ) {
    self.recordName = recordName
    self.serverErrorCode = serverErrorCode
    self.reason = reason
    self.retryAfter = retryAfter
    self.uuid = uuid
    self.redirectURL = redirectURL
  }

  internal init(from schema: Components.Schemas.RecordOperationFailure) {
    self.recordName = schema.recordName
    self.serverErrorCode = ServerErrorCode(rawValue: schema.serverErrorCode.rawValue)
    self.reason = schema.reason
    self.retryAfter = schema.retryAfter
    self.uuid = schema.uuid
    self.redirectURL = schema.redirectURL
  }
}
