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

import ConfigKeyKit
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

    /// Initialize with Swift Configuration's hierarchical provider setup
    public init() throws {
        let config = try MistDemoConfiguration()

        // CloudKit Core
        self.containerIdentifier = config.string(
            forKey: "container.identifier",
            default: "iCloud.com.brightdigit.MistDemo"
        ) ?? "iCloud.com.brightdigit.MistDemo"

        self.apiToken = config.string(
            forKey: "api.token",
            default: "",
            isSecret: true
        ) ?? ""

        let envString = config.string(
            forKey: "environment",
            default: "development"
        ) ?? "development"
        self.environment = envString == "production" ? .production : .development

        // Authentication
        self.webAuthToken = config.string(
            forKey: "web.auth.token",
            isSecret: true
        )

        self.keyID = config.string(
            forKey: "key.id"
        )

        self.privateKey = config.string(
            forKey: "private.key",
            isSecret: true
        )

        self.privateKeyFile = config.string(
            forKey: "private.key.file"
        )

        // Server
        self.host = config.string(
            forKey: "host",
            default: "127.0.0.1"
        ) ?? "127.0.0.1"

        self.port = config.int(
            forKey: "port",
            default: 8080
        ) ?? 8080

        // Test flags
        self.skipAuth = config.bool(
            forKey: "skip.auth",
            default: false
        )

        self.testAllAuth = config.bool(
            forKey: "test.all.auth",
            default: false
        )

        self.testApiOnly = config.bool(
            forKey: "test.api.only",
            default: false
        )

        self.testAdaptive = config.bool(
            forKey: "test.adaptive",
            default: false
        )

        self.testServerToServer = config.bool(
            forKey: "test.server.to.server",
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
