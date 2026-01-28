//
//  MistDemoConfig.swift
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

import Configuration
import Foundation
import MistKit

/// Centralized configuration for MistDemo
/// Implements hierarchical configuration using Swift Configuration (CLI → ENV → defaults)
public struct MistDemoConfig: Sendable {
    // MARK: - CloudKit Core Configuration

    /// CloudKit container identifier
    let containerIdentifier: String

    /// CloudKit API token (secret)
    let apiToken: String

    /// CloudKit environment (development or production)
    let environment: MistKit.Environment

    // MARK: - Authentication Configuration

    /// Web authentication token (secret)
    let webAuthToken: String?

    /// Server-to-server key ID
    let keyID: String?

    /// Server-to-server private key (secret)
    let privateKey: String?

    /// Path to server-to-server private key file
    let privateKeyFile: String?

    // MARK: - Server Configuration

    /// Server host for authentication
    let host: String

    /// Server port for authentication
    let port: Int

    // MARK: - Test Flags

    /// Skip authentication and use provided token directly
    let skipAuth: Bool

    /// Test all authentication methods
    let testAllAuth: Bool

    /// Test API-only authentication
    let testApiOnly: Bool

    /// Test AdaptiveTokenManager transitions
    let testAdaptive: Bool

    /// Test server-to-server authentication
    let testServerToServer: Bool

    // MARK: - Initialization

    /// Initialize with Swift Configuration's EnvironmentVariablesProvider + existing EnhancedConfigurationReader for CLI args
    public init() throws {
        // Use existing EnhancedConfigurationReader for CLI args + ENV vars + defaults
        // This already works perfectly
        let reader = EnhancedConfigurationReader()

        // CloudKit Core
        self.containerIdentifier = reader.string(
            key: "container.identifier",
            environmentKey: "CLOUDKIT_CONTAINER_ID",
            default: "iCloud.com.brightdigit.MistDemo"
        ) ?? "iCloud.com.brightdigit.MistDemo"

        self.apiToken = reader.string(
            key: "api.token",
            environmentKey: "CLOUDKIT_API_TOKEN",
            default: "",
            isSecret: true
        ) ?? ""

        let envString = reader.string(
            key: "environment",
            environmentKey: "CLOUDKIT_ENVIRONMENT",
            default: "development"
        ) ?? "development"
        self.environment = envString == "production" ? .production : .development

        // Authentication
        self.webAuthToken = reader.string(
            key: "web.auth.token",
            environmentKey: "CLOUDKIT_WEBAUTH_TOKEN",
            isSecret: true
        )

        self.keyID = reader.string(
            key: "key.id",
            environmentKey: "CLOUDKIT_KEY_ID"
        )

        self.privateKey = reader.string(
            key: "private.key",
            environmentKey: "CLOUDKIT_PRIVATE_KEY",
            isSecret: true
        )

        self.privateKeyFile = reader.string(
            key: "private.key.file",
            environmentKey: "CLOUDKIT_PRIVATE_KEY_FILE"
        )

        // Server
        self.host = reader.string(
            key: "host",
            environmentKey: "MISTDEMO_HOST",
            default: "127.0.0.1"
        ) ?? "127.0.0.1"

        self.port = reader.int(
            key: "port",
            environmentKey: "MISTDEMO_PORT",
            default: 8080
        ) ?? 8080

        // Test flags
        self.skipAuth = reader.bool(
            key: "skip.auth",
            environmentKey: "MISTDEMO_SKIP_AUTH",
            default: false
        )

        self.testAllAuth = reader.bool(
            key: "test.all.auth",
            environmentKey: "MISTDEMO_TEST_ALL_AUTH",
            default: false
        )

        self.testApiOnly = reader.bool(
            key: "test.api.only",
            environmentKey: "MISTDEMO_TEST_API_ONLY",
            default: false
        )

        self.testAdaptive = reader.bool(
            key: "test.adaptive",
            environmentKey: "MISTDEMO_TEST_ADAPTIVE",
            default: false
        )

        self.testServerToServer = reader.bool(
            key: "test.server.to.server",
            environmentKey: "MISTDEMO_TEST_SERVER_TO_SERVER",
            default: false
        )
    }
}

// MARK: - Configuration Extensions

extension MistDemoConfig {
    /// Resolve API token from configuration or environment
    public func resolvedApiToken() -> String {
        AuthenticationHelper.resolveAPIToken(apiToken)
    }

    /// Resolve web auth token from configuration or environment
    public func resolvedWebAuthToken() -> String? {
        AuthenticationHelper.resolveWebAuthToken(webAuthToken ?? "")
    }
}
