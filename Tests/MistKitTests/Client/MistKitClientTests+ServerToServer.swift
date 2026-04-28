//
//  MistKitClientTests+ServerToServer.swift
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

import Foundation
import Testing

@testable import MistKit

extension MistKitClientTests {
  @Test("MistKitClient rejects ServerToServerAuthManager with shared database")
  internal func serverToServerWithSharedDatabase() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      return
    }

    let privateKeyPEM = """
      -----BEGIN PRIVATE KEY-----
      MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
      OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
      1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
      -----END PRIVATE KEY-----
      """

    let tokenManager = try ServerToServerAuthManager(
      keyID: String(repeating: "0", count: 64),
      pemString: privateKeyPEM
    )

    let config = MistKitConfiguration(
      container: "iCloud.com.example.app",
      environment: .development,
      database: .shared,
      apiToken: ""
    )

    let transport = MockTransport()

    do {
      _ = try MistKitClient(
        configuration: config,
        tokenManager: tokenManager,
        transport: transport
      )
      Issue.record("Expected TokenManagerError for server-to-server with shared database")
    } catch let error as TokenManagerError {
      if case .invalidCredentials = error {
        // Success
      } else {
        Issue.record("Expected invalidCredentials error, got \(error)")
      }
    }
  }
}
