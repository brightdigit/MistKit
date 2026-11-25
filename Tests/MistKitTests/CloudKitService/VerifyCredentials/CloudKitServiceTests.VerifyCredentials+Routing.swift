//
//  CloudKitServiceTests.VerifyCredentials+Routing.swift
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

extension CloudKitServiceTests.VerifyCredentials {
  @Test("each check is signed with its own credential")
  internal func eachCheckUsesItsCredential() async throws {
    let transport = RecordingTransport(
      response: Self.reply(421, Recorded.authenticationRequired)
    )
    let service = CloudKitService(
      containerIdentifier: TestConstants.serviceContainerIdentifier,
      credentials: try Self.makeCredentials(apiTokenOnly: true, serverToServer: true),
      transport: transport
    )
    let result = try await service.verifyCredentials()
    #expect(result.apiTokenOnly.isAccepted)
    guard case .rejected(.authenticationRequired) = result.serverToServer else {
      Issue.record("expected rejected(.authenticationRequired), got \(result.serverToServer)")
      return
    }

    let sent = await transport.sent
    let caller = try #require(sent.first { $0.operationID == "getCaller" })
    let callerPath = try #require(caller.request.path)
    #expect(callerPath.contains("/public/users/caller"))
    #expect(callerPath.contains("ckAPIToken="))
    #expect(!callerPath.contains("ckWebAuthToken="))
    #expect(caller.request.headerFields[.cloudKitRequestKeyID] == nil)

    let zones = try #require(sent.first { $0.operationID == "listZones" })
    let zonesPath = try #require(zones.request.path)
    #expect(zonesPath.contains("/public/zones/list"))
    #expect(!zonesPath.contains("ckAPIToken="))
    #expect(zones.request.headerFields[.cloudKitRequestKeyID] == Self.keyID)
    #expect(sent.count == 2)
  }

  @Test("results and their descriptions carry no secrets")
  internal func noSecretsInResults() async throws {
    let badPEM = "-----BEGIN EC PRIVATE KEY-----\nc2VjcmV0LWtleQ==\n-----END EC PRIVATE KEY-----"
    let (webService, _) = Self.makeService(
      credentials: try Self.makeCredentials(webAuth: true, privateKey: .raw(badPEM)),
      responses: ["getCaller": Self.reply(421, Recorded.authenticationRequired)]
    )
    let (apiOnlyService, _) = Self.makeService(
      credentials: try Self.makeCredentials(apiTokenOnly: true),
      responses: ["getCaller": Self.reply(401, Recorded.apiTokenInvalid)]
    )
    let web = try await webService.verifyCredentials()
    let apiOnly = try await apiOnlyService.verifyCredentials()

    #expect(web.webAuth.error != nil)
    #expect(web.serverToServer.error != nil)
    #expect(apiOnly.apiTokenOnly.error != nil)
    let secrets = [TestConstants.apiToken, TestConstants.webAuthToken, "c2VjcmV0LWtleQ=="]
    for result in [web, apiOnly] {
      let texts =
        [String(describing: result), String(reflecting: result)]
        + CredentialKind.allCases.compactMap { result[$0].error?.localizedDescription }
      for text in texts {
        for secret in secrets {
          #expect(!text.contains(secret))
        }
      }
    }
  }
}
