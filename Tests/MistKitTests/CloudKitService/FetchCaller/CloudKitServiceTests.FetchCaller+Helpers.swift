//
//  CloudKitServiceTests.FetchCaller+Helpers.swift
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
internal import HTTPTypes
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.FetchCaller {
  private static let testAPIToken = TestConstants.apiToken

  internal static func makeSuccessfulService(
    userRecordName: String = "_user-caller",
    firstName: String? = "Test",
    lastName: String? = "User",
    emailAddress: String? = "caller@example.com"
  ) async throws -> CloudKitService {
    let responseProvider = try ResponseProvider.successfulFetchCaller(
      userRecordName: userRecordName,
      firstName: firstName,
      lastName: lastName,
      emailAddress: emailAddress
    )
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: testAPIToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
  }

  internal static func makeAuthErrorService() async throws -> CloudKitService {
    let responseProvider = ResponseProvider.authenticationError()
    let transport = MockTransport(responseProvider: responseProvider)
    return try CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: Credentials(
        apiAuth: APICredentials(
          apiToken: testAPIToken,
          webAuthToken: TestConstants.webAuthToken
        )
      ),
      transport: transport
    )
  }
}

// MARK: - FetchCaller Response Builders

extension ResponseProvider {
  internal static func successfulFetchCaller(
    userRecordName: String = "_user-caller",
    firstName: String? = "Test",
    lastName: String? = "User",
    emailAddress: String? = "caller@example.com"
  ) throws -> ResponseProvider {
    ResponseProvider(
      defaultResponse: try .successfulFetchCallerResponse(
        userRecordName: userRecordName,
        firstName: firstName,
        lastName: lastName,
        emailAddress: emailAddress
      )
    )
  }
}

extension ResponseConfig {
  internal static func successfulFetchCallerResponse(
    userRecordName: String = "_user-caller",
    firstName: String? = "Test",
    lastName: String? = "User",
    emailAddress: String? = "caller@example.com"
  ) throws -> ResponseConfig {
    var fields: [String] = ["\"userRecordName\": \"\(userRecordName)\""]
    if let firstName {
      fields.append("\"firstName\": \"\(firstName)\"")
    }
    if let lastName {
      fields.append("\"lastName\": \"\(lastName)\"")
    }
    if let emailAddress {
      fields.append("\"emailAddress\": \"\(emailAddress)\"")
    }

    let responseJSON = "{ \(fields.joined(separator: ", ")) }"

    var headers = HTTPFields()
    headers[.contentType] = "application/json"

    return ResponseConfig(
      statusCode: 200,
      headers: headers,
      body: responseJSON.data(using: .utf8),
      error: nil
    )
  }
}
