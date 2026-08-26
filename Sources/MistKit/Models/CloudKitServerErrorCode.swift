//
//  CloudKitServerErrorCode.swift
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

/// A CloudKit per-operation server error code.
///
/// Shared by every per-item failure type (``RecordOperationFailure``,
/// ``SubscriptionOperationFailure``) so the whole API surfaces the same set of
/// codes. Mirrors CloudKit's documented `serverErrorCode` values; an
/// ``unknown(_:)`` case carries any code not yet known to this version of
/// MistKit so forward-compatibility never drops information.
///
/// Wire string, documented HTTP status, and human summary for each known code
/// live in ``knownCatalog`` — the single source of truth used by both
/// ``CloudKitError`` construction and ``ServerErrorCodeDetail``.
public enum CloudKitServerErrorCode: Codable, Hashable, Sendable {
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

  /// Catalog row for one documented CloudKit `serverErrorCode`.
  internal struct CatalogEntry: Sendable {
    /// The typed case this row describes.
    internal let code: CloudKitServerErrorCode
    /// The raw CloudKit wire string, e.g. `"ACCESS_DENIED"`.
    internal let raw: String
    /// The HTTP status Apple documents for `raw`.
    internal let statusCode: Int
    /// Lowercase human summary used in error descriptions.
    internal let summary: String
  }

  /// The known catalog — single source of truth for raw string, status, and
  /// summary in both directions.
  internal static let knownCatalog: [CatalogEntry] = [
    CatalogEntry(
      code: .accessDenied, raw: "ACCESS_DENIED", statusCode: 403, summary: "access denied"
    ),
    CatalogEntry(
      code: .atomicError, raw: "ATOMIC_ERROR", statusCode: 400, summary: "atomic batch failure"
    ),
    CatalogEntry(
      code: .authenticationFailed, raw: "AUTHENTICATION_FAILED", statusCode: 401,
      summary: "authentication failed"
    ),
    CatalogEntry(
      code: .authenticationRequired, raw: "AUTHENTICATION_REQUIRED", statusCode: 421,
      summary: "authentication required"
    ),
    CatalogEntry(
      code: .badRequest, raw: "BAD_REQUEST", statusCode: 400, summary: "bad request"
    ),
    CatalogEntry(
      code: .conflict, raw: "CONFLICT", statusCode: 409, summary: "conflict"
    ),
    CatalogEntry(
      code: .exists, raw: "EXISTS", statusCode: 409, summary: "already exists"
    ),
    CatalogEntry(
      code: .internalError, raw: "INTERNAL_ERROR", statusCode: 500, summary: "internal server error"
    ),
    CatalogEntry(
      code: .notFound, raw: "NOT_FOUND", statusCode: 404, summary: "not found"
    ),
    CatalogEntry(
      code: .quotaExceeded, raw: "QUOTA_EXCEEDED", statusCode: 413, summary: "quota exceeded"
    ),
    CatalogEntry(
      code: .throttled, raw: "THROTTLED", statusCode: 429, summary: "throttled"
    ),
    CatalogEntry(
      code: .tryAgainLater, raw: "TRY_AGAIN_LATER", statusCode: 503, summary: "try again later"
    ),
    CatalogEntry(
      code: .validatingReferenceError, raw: "VALIDATING_REFERENCE_ERROR", statusCode: 412,
      summary: "reference validation error"
    ),
    CatalogEntry(
      code: .zoneNotFound, raw: "ZONE_NOT_FOUND", statusCode: 404, summary: "zone not found"
    ),
  ]

  /// Lookup from raw CloudKit string → known case.
  private static let byRawValue: [String: CloudKitServerErrorCode] = Dictionary(
    uniqueKeysWithValues: knownCatalog.map { ($0.raw, $0.code) }
  )

  /// Lookup from known case → catalog row.
  private static let byCode: [CloudKitServerErrorCode: CatalogEntry] = Dictionary(
    uniqueKeysWithValues: knownCatalog.map { ($0.code, $0) }
  )

  /// The raw CloudKit string for this code (e.g. `"NOT_FOUND"`).
  public var rawValue: String {
    if case .unknown(let raw) = self {
      return raw
    }
    return Self.byCode[self]?.raw ?? ""
  }

  /// The HTTP status Apple documents for this code, or `nil` for ``unknown(_:)``.
  public var statusCode: Int? {
    Self.byCode[self]?.statusCode
  }

  /// Lowercase human summary for this code, or `nil` for ``unknown(_:)``.
  public var summary: String? {
    Self.byCode[self]?.summary
  }

  /// Catalog row for a known code, or `nil` for ``unknown(_:)``.
  internal var catalogEntry: CatalogEntry? {
    Self.byCode[self]
  }

  /// Maps a raw CloudKit string to a known case, or ``unknown(_:)``.
  public init(rawValue: String) {
    self = Self.byRawValue[rawValue] ?? .unknown(rawValue)
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
