//
//  MistKitClientFactoryTests+Helpers.swift
//  MistDemo
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
import MistKit

@testable import MistDemoKit

extension MistKitClientFactoryTests {
  internal static let validPrivateKey: String = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgTest1234567890Test
    1234567890Test1234567890hRACBiCZLT+JFnrEF6+Lq/CBATF/2FJGKe0kWDAuBgNV
    BAsTJ0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zMRQwEgYDVQQD
    -----END PRIVATE KEY-----
    """

  internal static func isServerToServerSupported() -> Bool {
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
      return true
    } else {
      return false
    }
  }

  internal static func makeConfig(
    containerIdentifier: String = "iCloud.com.test.App",
    apiToken: String = "test-api-token",
    environment: MistKit.Environment = .development,
    database: MistKit.Database = .private,
    webAuthToken: String? = "test-web-auth-token",
    keyID: String? = nil,
    privateKey: String? = nil,
    privateKeyFile: String? = nil,
    host: String = "127.0.0.1",
    port: Int = 8_080,
    authTimeout: Double = 300,
    skipAuth: Bool = false,
    testAllAuth: Bool = false,
    testApiOnly: Bool = false,
    testAdaptive: Bool = false,
    testServerToServer: Bool = false,
    badCredentials: Bool = false
  ) async throws -> MistDemoConfig {
    try await MistDemoConfig(
      containerIdentifier: containerIdentifier,
      apiToken: apiToken,
      environment: environment,
      database: database,
      webAuthToken: webAuthToken,
      keyID: keyID,
      privateKey: privateKey,
      privateKeyFile: privateKeyFile,
      host: host,
      port: port,
      authTimeout: authTimeout,
      skipAuth: skipAuth,
      testAllAuth: testAllAuth,
      testApiOnly: testApiOnly,
      testAdaptive: testAdaptive,
      testServerToServer: testServerToServer,
      badCredentials: badCredentials
    )
  }
}
