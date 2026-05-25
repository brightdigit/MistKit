//
//  SubscriptionOperationFailure.swift
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

/// A per-subscription failure returned inline in a CloudKit
/// `modifySubscriptions` response.
///
/// CloudKit reports per-operation failures as error entries within the
/// otherwise-successful (HTTP 200) `subscriptions` array, carrying the failed
/// subscription's identifier, a server error code, and optional retry/redirect
/// hints. This is the subscriptions analogue of ``RecordOperationFailure`` —
/// without it, a failed create (e.g. CloudKit's `INTERNAL_ERROR` /
/// "could not find subscription we just created") would be silently dropped.
///
/// This is a data payload describing a failure, **not** a Swift `Error` type;
/// it is surfaced via ``SubscriptionResult/failure(_:)`` from
/// `modifySubscriptions`, and wrapped in
/// ``CloudKitError/subscriptionOperationFailed(_:)`` (which *is* an `Error`)
/// when the single-subscription convenience (`createSubscription`) hits one.
public struct SubscriptionOperationFailure: Codable, Hashable, Sendable {
  /// The CloudKit server error code for a per-subscription failure.
  public typealias ServerErrorCode = CloudKitServerErrorCode

  /// The identifier of the subscription the operation failed on.
  public let subscriptionID: String
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

  /// Creates a per-subscription failure value.
  public init(
    subscriptionID: String,
    serverErrorCode: ServerErrorCode,
    reason: String? = nil,
    retryAfter: Int? = nil,
    uuid: String? = nil,
    redirectURL: String? = nil
  ) {
    self.subscriptionID = subscriptionID
    self.serverErrorCode = serverErrorCode
    self.reason = reason
    self.retryAfter = retryAfter
    self.uuid = uuid
    self.redirectURL = redirectURL
  }

  internal init(from schema: Components.Schemas.SubscriptionOperationFailure) {
    let serverErrorCode = ServerErrorCode(rawValue: schema.serverErrorCode.rawValue)
    // The generated `serverErrorCodePayload` is a closed enum mirroring the
    // schema, so a `.unknown` here means our `knownPairs` table drifted from
    // the regenerated schema — assert loudly (test-overridable) while still
    // preserving the raw code for forward-compatibility in release.
    if case .unknown(let raw) = serverErrorCode {
      ConversionFailureReporter.assertionHandler(
        "Unmapped CloudKit serverErrorCode \"\(raw)\" — update CloudKitServerErrorCode.knownPairs",
        #fileID,
        #line
      )
    }
    self.subscriptionID = schema.subscriptionID
    self.serverErrorCode = serverErrorCode
    self.reason = schema.reason
    self.retryAfter = schema.retryAfter
    self.uuid = schema.uuid
    self.redirectURL = schema.redirectURL
  }
}
