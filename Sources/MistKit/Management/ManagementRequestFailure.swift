//
//  ManagementRequestFailure.swift
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

internal import Foundation

/// A CloudKit Management API error response.
///
/// Decoded from the JSON `RequestError` CKTool JS 1.3.2 declares for every
/// non-success response: `code`, `message`, `reason`, and the optional
/// `detailedMessage`, `requestUuid` and `retryAfterSeconds`.
public struct ManagementRequestFailure: Sendable, Hashable, Decodable {
  private enum CodingKeys: String, CodingKey {
    case code
    case message
    case reason
    case detailedMessage
    case requestUUID = "requestUuid"
    case retryAfterSeconds
  }

  /// The HTTP status of the response.
  public let statusCode: Int
  /// The status code the body reports (`code`).
  public let code: Int
  /// The error code string (`message`), such as `AUTHENTICATION_FAILED`.
  public let message: String
  /// Why the request failed (`reason`).
  public let reason: String
  /// More detail, when CloudKit gives it.
  public let detailedMessage: String?
  /// CloudKit's identifier for the failed request, for support.
  public let requestUUID: String?
  /// Seconds to wait before retrying, when CloudKit asks for a delay.
  public let retryAfterSeconds: Int?

  /// Creates a failure.
  public init(
    statusCode: Int,
    code: Int,
    message: String,
    reason: String,
    detailedMessage: String?,
    requestUUID: String?,
    retryAfterSeconds: Int?
  ) {
    self.statusCode = statusCode
    self.code = code
    self.message = message
    self.reason = reason
    self.detailedMessage = detailedMessage
    self.requestUUID = requestUUID
    self.retryAfterSeconds = retryAfterSeconds
  }

  /// Decodes the body; ``statusCode`` is set from ``code`` until the
  /// response status replaces it.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let code = try container.decode(Int.self, forKey: .code)
    self.init(
      statusCode: code,
      code: code,
      message: try container.decode(String.self, forKey: .message),
      reason: try container.decode(String.self, forKey: .reason),
      detailedMessage: try container.decodeIfPresent(String.self, forKey: .detailedMessage),
      requestUUID: try container.decodeIfPresent(String.self, forKey: .requestUUID),
      retryAfterSeconds: try container.decodeIfPresent(Int.self, forKey: .retryAfterSeconds)
    )
  }

  internal func with(statusCode: Int) -> ManagementRequestFailure {
    ManagementRequestFailure(
      statusCode: statusCode,
      code: code,
      message: message,
      reason: reason,
      detailedMessage: detailedMessage,
      requestUUID: requestUUID,
      retryAfterSeconds: retryAfterSeconds
    )
  }
}
