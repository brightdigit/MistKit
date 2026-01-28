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

// MARK: - Configuration Errors

enum ConfigurationError: LocalizedError {
    case missingAPIToken
    case invalidEnvironment(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIToken:
            return "CloudKit API token is required. Set CLOUDKIT_API_TOKEN environment variable or use --api-token"
        case .invalidEnvironment(let env):
            return "Invalid environment '\(env)'. Must be 'development' or 'production'"
        }
    }
}

// MARK: - Enhanced Configuration Reader

/// Configuration reader implementing hierarchical resolution (CLI → ENV → defaults)
struct EnhancedConfigurationReader {

    init() {}

    /// Read string value with hierarchy: command line → environment → default
    func string(key: String, environmentKey: String? = nil, default: String? = nil, isSecret: Bool = false) -> String? {
        // 1. Check command line arguments
        if let value = getCommandLineValue(for: key) {
            return value
        }

        // 2. Check environment variables
        if let envKey = environmentKey, let value = ProcessInfo.processInfo.environment[envKey] {
            return value
        }

        // 3. Return default
        return `default`
    }

    /// Read int value with hierarchy
    func int(key: String, environmentKey: String? = nil, default: Int? = nil) -> Int? {
        if let stringValue = string(key: key, environmentKey: environmentKey, default: `default`.map(String.init)) {
            return Int(stringValue)
        }
        return nil
    }

    /// Read bool value with hierarchy
    func bool(key: String, environmentKey: String? = nil, default: Bool = false) -> Bool {
        if let stringValue = string(key: key, environmentKey: environmentKey, default: String(`default`)) {
            return stringValue.lowercased() == "true" || stringValue == "1"
        }
        return `default`
    }

    /// Get value from command line arguments
    private func getCommandLineValue(for key: String) -> String? {
        let args = CommandLine.arguments

        // Convert key to command line format (e.g., "api.token" -> "--api-token")
        let argName = "--" + key.replacingOccurrences(of: ".", with: "-")

        if let index = args.firstIndex(of: argName), index + 1 < args.count {
            return args[index + 1]
        }

        // Also check for alternative argument names
        let alternativeNames = getAlternativeArgNames(for: key)
        for altName in alternativeNames {
            if let index = args.firstIndex(of: altName), index + 1 < args.count {
                return args[index + 1]
            }
        }

        // Check for flags (boolean values)
        if args.contains(argName) {
            return "true"
        }

        // Check alternative flags
        for altName in alternativeNames {
            if args.contains(altName) {
                return "true"
            }
        }

        return nil
    }

    /// Get alternative command line argument names for common keys
    private func getAlternativeArgNames(for key: String) -> [String] {
        switch key {
        case "container.identifier":
            return ["--container-identifier", "-c"]
        case "api.token":
            return ["--api-token", "-a"]
        case "web.auth.token":
            return ["--web-auth-token"]
        case "private.key.file":
            return ["--private-key-file"]
        case "private.key":
            return ["--private-key"]
        case "key.id":
            return ["--key-id"]
        case "skip.auth":
            return ["--skip-auth"]
        case "test.all.auth":
            return ["--test-all-auth"]
        case "test.api.only":
            return ["--test-api-only"]
        case "test.adaptive":
            return ["--test-adaptive"]
        case "test.server.to.server":
            return ["--test-server-to-server"]
        case "port":
            return ["-p"]
        default:
            return []
        }
    }
}
