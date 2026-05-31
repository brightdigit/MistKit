//
//  OperationFailure.swift
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

/// A per-item failure returned inline in a CloudKit batch response.
///
/// CloudKit reports per-operation failures as error entries within the
/// otherwise-successful (HTTP 200) `records` or `subscriptions` array, carrying
/// the failed item's identifier, a server error code, and optional
/// retry/redirect hints. `OperationFailure` is the unified data payload
/// describing such a failure; it is **not** a Swift `Error` — it is surfaced
/// via ``OperationResult/failure(_:)`` and wrapped in ``CloudKitError`` (via
/// ``OperationFailureTarget/wrap(_:)``) when a single-item convenience method
/// hits one.
///
/// The phantom ``OperationFailureTarget`` parameter distinguishes per-record
/// failures (``RecordOperationFailure``) from per-subscription failures
/// (``SubscriptionOperationFailure``) at the type level so the compiler
/// prevents mixing them in batch-result arrays.
public struct OperationFailure<Target: OperationFailureTarget>:
  Codable, Hashable, Sendable
{
  /// The CloudKit server error code for a per-item failure.
  public typealias ServerErrorCode = CloudKitServerErrorCode

  /// The wire identifier of the item the operation failed on
  /// (a record name for ``RecordOperationFailure``, a subscription ID for
  /// ``SubscriptionOperationFailure``).
  public let identifier: String
  /// The CloudKit server error code for the failure.
  public let serverErrorCode: ServerErrorCode
  /// A human-readable reason for the failure, if provided.
  public let reason: String?
  /// Suggested seconds to wait before retrying. Absent if not retryable.
  public let retryAfter: Int?
  /// A unique identifier for this error.
  public let uuid: String?
  /// Redirect URL for sign-in; present when `serverErrorCode` is
  /// ``CloudKitServerErrorCode/authenticationRequired``.
  public let redirectURL: String?

  /// Creates a per-item failure value.
  public init(
    identifier: String,
    serverErrorCode: ServerErrorCode,
    reason: String? = nil,
    retryAfter: Int? = nil,
    uuid: String? = nil,
    redirectURL: String? = nil
  ) {
    self.identifier = identifier
    self.serverErrorCode = serverErrorCode
    self.reason = reason
    self.retryAfter = retryAfter
    self.uuid = uuid
    self.redirectURL = redirectURL
  }

  /// Shared initializer for per-target adapters: takes the wire identifier
  /// plus the generated `OperationFailureCommon` payload (everything the two
  /// failure schemas share via `allOf`).
  internal init(
    identifier: String,
    common: Components.Schemas.OperationFailureCommon
  ) {
    let serverErrorCode = ServerErrorCode(rawValue: common.serverErrorCode.rawValue)
    // The generated `OperationFailureServerErrorCode` is a closed enum mirroring
    // the schema, so a `.unknown` here means our `knownPairs` table drifted
    // from the regenerated schema — assert loudly (test-overridable) while
    // still preserving the raw code for forward-compatibility in release.
    if case .unknown(let raw) = serverErrorCode {
      ConversionFailureReporter.assertionHandler(
        "Unmapped CloudKit serverErrorCode \"\(raw)\""
          + " — update CloudKitServerErrorCode.knownPairs",
        #fileID,
        #line
      )
    }
    self.init(
      identifier: identifier,
      serverErrorCode: serverErrorCode,
      reason: common.reason,
      retryAfter: common.retryAfter,
      uuid: common.uuid,
      redirectURL: common.redirectURL
    )
  }
}
