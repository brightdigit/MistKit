//
//  CloudKitServiceTests.VerifyCredentials+Helpers.swift
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

internal import Crypto
internal import Foundation
internal import HTTPTypes
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.VerifyCredentials {
  /// Bodies recorded from a real container (`Fixtures/Recorded/`, 2026-11-17).
  internal enum Recorded {
    /// `users/current.json`: `users/caller` with a web-auth token, HTTP 200.
    internal static let caller = #"{ "userRecordName": "_fixtureUser1" }"#

    /// `zones/list-public.json`: public `zones/list`, server-to-server, HTTP 200.
    internal static let publicZones = """
      {
        "zones": [
          {
            "zoneID": {
              "zoneName": "_defaultZone",
              "ownerRecordName": "_fixtureUser1",
              "zoneType": "DEFAULT_ZONE"
            },
            "atomic": false
          }
        ]
      }
      """

    /// `errors/authentication-required.json`: an API token without a web-auth
    /// token (or an invalid web-auth token), HTTP 421.
    internal static let authenticationRequired = """
      {
        "uuid": "b5845d7b-fae6-4511-9067-038c19f58bc4",
        "serverErrorCode": "AUTHENTICATION_REQUIRED",
        "reason": "request needs authorization",
        "redirectURL": "https://idmsa.apple.com/IDMSWebAuth/auth?oauth_token=OATTKN-fixture"
      }
      """

    /// `errors/api-token-invalid.json`: a made-up API token, HTTP 401.
    internal static let apiTokenInvalid = """
      {
        "uuid": "dc13704d-686e-497d-b0fc-d35cb36caea2",
        "reason": "Authentication failed, please check you have the correct API Token \
      for this container",
        "serverErrorCode": "AUTHENTICATION_FAILED"
      }
      """
  }

  /// The server-to-server key ID the tests use.
  internal static let keyID = "fixture-key-id-0123456789abcdef"

  /// A JSON response with `status`.
  internal static func reply(_ status: Int, _ json: String) -> ResponseConfig {
    var headers = HTTPFields()
    headers[.contentType] = "application/json"
    return ResponseConfig(statusCode: status, headers: headers, body: Data(json.utf8))
  }

  /// A fresh P-256 private key in PEM form.
  internal static func makePEM() -> String {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("P256 requires macOS 11.0+ / iOS 14.0+ / tvOS 14.0+ / watchOS 7.0+")
      return ""
    }
    return P256.Signing.PrivateKey().pemRepresentation
  }

  /// `Credentials` with the given kinds configured.
  internal static func makeCredentials(
    webAuth: Bool = false,
    apiTokenOnly: Bool = false,
    serverToServer: Bool = false,
    privateKey: PrivateKeyMaterial? = nil
  ) throws -> Credentials {
    let apiAuth: APICredentials? =
      if webAuth {
        APICredentials(
          apiToken: TestConstants.apiToken,
          webAuthToken: TestConstants.webAuthToken
        )
      } else if apiTokenOnly {
        APICredentials(apiToken: TestConstants.apiToken)
      } else {
        nil
      }
    let s2s: ServerToServerCredentials? =
      if serverToServer || privateKey != nil {
        ServerToServerCredentials(
          keyID: keyID,
          privateKey: privateKey ?? .raw(makePEM())
        )
      } else {
        nil
      }
    return try Credentials(serverToServer: s2s, apiAuth: apiAuth)
  }

  /// A service over `MockTransport` answering each operation with
  /// `responses[operationID]`, or HTTP 500 for an operation it wasn't told
  /// about.
  internal static func makeService(
    credentials: Credentials,
    responses: [String: ResponseConfig]
  ) -> (CloudKitService, ResponseProvider) {
    let provider = ResponseProvider(
      responses: responses,
      defaultResponse: reply(500, #"{"serverErrorCode":"INTERNAL_ERROR"}"#)
    )
    let service = CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: credentials,
      transport: MockTransport(responseProvider: provider)
    )
    return (service, provider)
  }
}
