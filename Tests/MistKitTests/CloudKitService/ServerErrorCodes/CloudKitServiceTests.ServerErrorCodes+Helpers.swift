//
//  CloudKitServiceTests.ServerErrorCodes+Helpers.swift
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

internal import Testing

@testable import MistKit

extension CloudKitServiceTests.ServerErrorCodes {
  /// A service whose transport answers every request with a CloudKit failure
  /// body carrying `serverErrorCode` at `statusCode`.
  internal static func makeService(
    statusCode: Int,
    serverErrorCode: String,
    reason: String
  ) throws -> CloudKitService {
    let provider = ResponseProvider(
      defaultResponse: .cloudKitError(
        statusCode: statusCode,
        serverErrorCode: serverErrorCode,
        reason: reason
      )
    )
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(apiAuth: APICredentials(apiToken: TestConstants.apiToken)),
      transport: MockTransport(responseProvider: provider)
    )
  }

  /// Payload-free label for the case `error` actually landed in, so a test can
  /// assert on case identity without requiring `CloudKitError: Equatable`.
  // swiftlint:disable:next cyclomatic_complexity
  internal static func caseLabel(of error: CloudKitError) -> String {
    switch error {
    case .accessDenied: return "accessDenied"
    case .atomicFailure: return "atomicFailure"
    case .authenticationFailed: return "authenticationFailed"
    case .authenticationRequired: return "authenticationRequired"
    case .badRequest: return "badRequest"
    case .conflict: return "conflict"
    case .exists: return "exists"
    case .internalServerError: return "internalServerError"
    case .notFound: return "notFound"
    case .quotaExceeded: return "quotaExceeded"
    case .throttled: return "throttled"
    case .tryAgainLater: return "tryAgainLater"
    case .validatingReferenceError: return "validatingReferenceError"
    case .zoneNotFound: return "zoneNotFound"
    case .unknownServerError: return "unknownServerError"
    case .httpErrorWithDetails: return "httpErrorWithDetails"
    default: return "other(\(error))"
    }
  }
}
