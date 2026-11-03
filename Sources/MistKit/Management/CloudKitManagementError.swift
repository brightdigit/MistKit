//
//  CloudKitManagementError.swift
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

public import Foundation

/// Errors from ``CloudKitManagementService``.
public enum CloudKitManagementError: LocalizedError, Sendable {
  /// The Management API answered with a JSON `RequestError`.
  case requestFailed(ManagementRequestFailure)
  /// A non-success response whose body wasn't a `RequestError`. `body` is the
  /// body as UTF-8 text, when it is text.
  case httpError(statusCode: Int, body: String?)
  /// A success response MistKit couldn't use.
  case invalidResponse(reason: String)
  /// The schema export wasn't valid CloudKit Schema Language. `text` is the
  /// export as received, so a caller can still show or save it.
  case invalidSchema(SchemaParseError, text: String)

  /// A message that never includes the management token.
  public var errorDescription: String? {
    switch self {
    case .requestFailed(let failure):
      "CloudKit Management API error \(failure.statusCode) \(failure.message): \(failure.reason)"
    case .httpError(let statusCode, _):
      "CloudKit Management API HTTP \(statusCode)"
    case .invalidResponse(let reason):
      "CloudKit Management API returned an unusable response: \(reason)"
    case .invalidSchema(let parseError, _):
      "CloudKit Management API returned a schema MistKit couldn't parse. "
        + (parseError.errorDescription ?? "")
    }
  }

  /// Classifies a non-success response.
  internal init(statusCode: Int, body: Data) {
    if let failure = try? JSONDecoder().decode(ManagementRequestFailure.self, from: body) {
      self = .requestFailed(failure.with(statusCode: statusCode))
    } else {
      self = .httpError(
        statusCode: statusCode,
        body: body.isEmpty ? nil : String(data: body, encoding: .utf8)
      )
    }
  }
}
