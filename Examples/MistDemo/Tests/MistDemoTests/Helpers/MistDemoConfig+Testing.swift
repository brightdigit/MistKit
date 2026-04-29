//
//  MistDemoConfig+Testing.swift
//  MistDemoTests
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

import Configuration
import Foundation
import MistKit
@testable import MistDemo

extension MistDemoConfig {
    /// Create a test configuration with default values
    init() async throws {
        let configuration = try MistDemoConfiguration()
        self = try await MistDemoConfig(configuration: configuration)
    }

    /// Create a test configuration with custom values
    init(
        containerIdentifier: String = "iCloud.com.test.App",
        apiToken: String = "test-api-token",
        environment: MistKit.Environment = .development,
        webAuthToken: String? = nil,
        keyID: String? = nil,
        privateKey: String? = nil,
        privateKeyFile: String? = nil,
        host: String = "127.0.0.1",
        port: Int = 8080,
        authTimeout: Double = 300,
        skipAuth: Bool = false,
        testAllAuth: Bool = false,
        testApiOnly: Bool = false,
        testAdaptive: Bool = false,
        testServerToServer: Bool = false
    ) async throws {
        let envString = environment == .production ? "production" : "development"

        func key(_ path: String) -> AbsoluteConfigKey {
            AbsoluteConfigKey(path.split(separator: ".").map(String.init), context: [:])
        }

        var values: [AbsoluteConfigKey: ConfigValue] = [
            key("container.identifier"): .init(stringLiteral: containerIdentifier),
            key("api.token"): .init(stringLiteral: apiToken),
            key("environment"): .init(stringLiteral: envString),
            key("host"): .init(stringLiteral: host),
            key("port"): .init(integerLiteral: port),
            key("auth.timeout"): .init(integerLiteral: Int(authTimeout)),
            key("skip.auth"): .init(booleanLiteral: skipAuth),
            key("test.all.auth"): .init(booleanLiteral: testAllAuth),
            key("test.api.only"): .init(booleanLiteral: testApiOnly),
            key("test.adaptive"): .init(booleanLiteral: testAdaptive),
            key("test.server.to.server"): .init(booleanLiteral: testServerToServer)
        ]

        if let webAuthToken {
            values[key("web.auth.token")] = .init(stringLiteral: webAuthToken)
        }
        if let keyID {
            values[key("key.id")] = .init(stringLiteral: keyID)
        }
        if let privateKey {
            values[key("private.key")] = .init(stringLiteral: privateKey)
        }
        if let privateKeyFile {
            values[key("private.key.file")] = .init(stringLiteral: privateKeyFile)
        }

        let testProvider = InMemoryProvider(values: values)
        let configuration = MistDemoConfiguration(testProvider: testProvider)
        self = try await MistDemoConfig(configuration: configuration)
    }
}
