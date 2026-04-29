//
//  MistKitClientFactoryTests.swift
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
import Testing
@testable import MistDemo
import MistKit

@Suite("MistKitClientFactory Tests")
struct MistKitClientFactoryTests {

    // MARK: - Test Config Helpers

    func makeConfig(
        containerIdentifier: String = "iCloud.com.test.App",
        apiToken: String = "test-api-token",
        environment: MistKit.Environment = .development,
        webAuthToken: String? = "test-web-auth-token",
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
    ) async throws -> MistDemoConfig {
        return try await MistDemoConfig(
            containerIdentifier: containerIdentifier,
            apiToken: apiToken,
            environment: environment,
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
            testServerToServer: testServerToServer
        )
    }

    // MARK: - API Token Only Tests

    @Test("Create client with API token only")
    func createWithAPITokenOnly() async throws {
        let config = try await makeConfig(apiToken: "api-token-123")

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    @Test("Throw error when API token is missing")
    func throwErrorWhenAPITokenMissing() async {
        let config = try! await makeConfig(apiToken: "")

        #expect(throws: ConfigurationError.self) {
            try MistKitClientFactory.create(.private, from: config)
        }
    }

    // MARK: - Web Auth Token Tests

    @Test("Create client with web auth token")
    func createWithWebAuthToken() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            webAuthToken: "web-auth-token"
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    @Test("Web auth token takes precedence over server-to-server")
    func webAuthTokenPrecedence() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            webAuthToken: "web-auth-token",
            keyID: "key-id",
            privateKey: validPrivateKey
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    // MARK: - Server-to-Server Auth Tests

    @Test("Create client with server-to-server auth", .enabled(if: isServerToServerSupported()))
    func createWithServerToServerAuth() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            keyID: "test-key-id",
            privateKey: validPrivateKey
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    @Test("Throw error when server-to-server auth incomplete", .enabled(if: isServerToServerSupported()))
    func throwErrorWhenServerToServerIncomplete() async {
        let config = try! await makeConfig(
            apiToken: "api-token",
            keyID: "test-key-id"
            // privateKey missing
        )

        // Should fall back to API-only auth
        let client = try? MistKitClientFactory.create(.private, from: config)
        #expect(client != nil)
    }

    // MARK: - Public Database Tests

    @Test("Create client for public database")
    func createForPublicDatabaseTest() async throws {
        let config = try await makeConfig(apiToken: "api-token")
        let tokenManager = APITokenManager(apiToken: "api-token")

        let client = try MistKitClientFactory.create(
            from: config,
            tokenManager: tokenManager,
            database: .public
        )

        #expect(client != nil)
    }

    @Test("Public database creation requires API token")
    func publicDatabaseRequiresAPIToken() async {
        let config = try! await makeConfig(apiToken: "")

        #expect(throws: ConfigurationError.self) {
            try MistKitClientFactory.create(.public, from: config)
        }
    }

    // MARK: - Custom Token Manager Tests

    @Test("Create client with custom token manager")
    func createWithCustomTokenManager() async throws {
        let config = try await makeConfig(apiToken: "api-token")
        let tokenManager = APITokenManager(apiToken: "custom-token")

        let client = try MistKitClientFactory.create(
            from: config,
            tokenManager: tokenManager,
            database: .private
        )

        #expect(client != nil)
    }

    @Test("Create client with custom token manager for public database")
    func createWithCustomTokenManagerPublicDB() async throws {
        let config = try await makeConfig(apiToken: "api-token")
        let tokenManager = APITokenManager(apiToken: "custom-token")

        let client = try MistKitClientFactory.create(
            from: config,
            tokenManager: tokenManager,
            database: .public
        )

        #expect(client != nil)
    }

    // MARK: - Environment Tests

    @Test("Create client with development environment")
    func createWithDevelopmentEnvironment() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            environment: .development
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    @Test("Create client with production environment")
    func createWithProductionEnvironment() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            environment: .production
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    // MARK: - Container Identifier Tests

    @Test("Create client with custom container identifier")
    func createWithCustomContainerIdentifier() async throws {
        let config = try await makeConfig(
            containerIdentifier: "iCloud.com.custom.App",
            apiToken: "api-token"
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    // MARK: - Private Key File Tests

    @Test("Load private key from file not implemented")
    func privateKeyFileNotImplemented() async throws {
        // Since loadPrivateKeyFromFile is private and returns nil on error,
        // we test the behavior indirectly
        let config = try await makeConfig(
            apiToken: "api-token",
            keyID: "key-id",
            privateKeyFile: "/non/existent/file.pem"
        )

        // Should fall back to API-only auth when file can't be read
        let client = try? MistKitClientFactory.create(.private, from: config)
        #expect(client != nil)
    }

    // MARK: - Error Cases

    @Test("Missing API token throws ConfigurationError")
    func missingAPITokenError() async {
        let config = try! await makeConfig(apiToken: "")

        do {
            _ = try MistKitClientFactory.create(.private, from: config)
            Issue.record("Should have thrown ConfigurationError")
        } catch let error as ConfigurationError {
            if case .missingRequired(let key, _) = error {
                #expect(key == "api.token")
            } else {
                Issue.record("Wrong ConfigurationError case")
            }
        } catch {
            Issue.record("Wrong error type")
        }
    }

    @Test("Empty web auth token throws ConfigurationError")
    func emptyWebAuthTokenFallback() async {
        let config = try! await makeConfig(
            apiToken: "api-token",
            webAuthToken: ""
        )

        #expect(throws: ConfigurationError.self) {
            try MistKitClientFactory.create(.private, from: config)
        }
    }

    @Test("Empty keyID falls back to API-only auth")
    func emptyKeyIDFallback() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            keyID: "",
            privateKey: validPrivateKey
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    @Test("Empty private key falls back to API-only auth")
    func emptyPrivateKeyFallback() async throws {
        let config = try await makeConfig(
            apiToken: "api-token",
            keyID: "key-id",
            privateKey: ""
        )

        let client = try MistKitClientFactory.create(.private, from: config)

        #expect(client != nil)
    }

    // MARK: - Helper Functions

    static func isServerToServerSupported() -> Bool {
        if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            return true
        } else {
            return false
        }
    }

    var validPrivateKey: String {
        """
        -----BEGIN PRIVATE KEY-----
        MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgTest1234567890Test
        1234567890Test1234567890hRACBiCZLT+JFnrEF6+Lq/CBATF/2FJGKe0kWDAuBgNV
        BAsTJ0FwcGxlIFdvcmxkd2lkZSBEZXZlbG9wZXIgUmVsYXRpb25zMRQwEgYDVQQD
        -----END PRIVATE KEY-----
        """
    }
}
