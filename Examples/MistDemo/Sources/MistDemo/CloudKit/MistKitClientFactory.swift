//
//  MistKitClientFactory.swift
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

public import Foundation
public import MistKit

/// Factory for creating MistKit CloudKitService instances from MistDemo configuration
public struct MistKitClientFactory: Sendable {
    
    /// Create a CloudKitService for private database operations.
    ///
    /// Requires `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN` (web authentication).
    /// - Parameter config: The base MistDemo configuration
    /// - Returns: A configured CloudKitService instance for the private database
    /// - Throws: ConfigurationError if required credentials are missing
    public static func create(from config: MistDemoConfig) throws -> CloudKitService {
        let apiToken = AuthenticationHelper.resolveAPIToken(config.apiToken)
        guard !apiToken.isEmpty else {
            throw ConfigurationError.missingRequired("api.token",
                suggestion: "Provide via CLOUDKIT_API_TOKEN environment variable")
        }

        let webAuthToken = config.webAuthToken.flatMap { AuthenticationHelper.resolveWebAuthToken($0) }
        guard let webAuthToken else {
            throw ConfigurationError.missingRequired("web.auth.token",
                suggestion: "Provide via CLOUDKIT_WEB_AUTH_TOKEN or run `mistdemo auth-token`")
        }

        let tokenManager = WebAuthTokenManager(apiToken: apiToken, webAuthToken: webAuthToken)

        return try CloudKitService(
            containerIdentifier: config.containerIdentifier,
            tokenManager: tokenManager,
            environment: config.environment,
            database: .private
        )
    }

    /// Create a CloudKitService for public database operations.
    ///
    /// Requires `CLOUDKIT_KEY_ID` + `CLOUDKIT_PRIVATE_KEY[_FILE]` (server-to-server authentication).
    /// - Parameter config: The base MistDemo configuration
    /// - Returns: A configured CloudKitService instance for the public database
    /// - Throws: ConfigurationError if required credentials are missing
    public static func createForPublicDatabase(from config: MistDemoConfig) throws -> CloudKitService {
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
            throw ConfigurationError.unsupportedPlatform(
                "Public database access requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
            )
        }
        guard let keyID = config.keyID, !keyID.isEmpty else {
            throw ConfigurationError.missingRequired("key.id",
                suggestion: "Provide via CLOUDKIT_KEY_ID environment variable")
        }
        guard let rawKey = config.privateKey ?? loadPrivateKeyFromFile(config.privateKeyFile),
              !rawKey.isEmpty else {
            throw ConfigurationError.missingRequired("private.key",
                suggestion: "Provide via CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH")
        }
        let privateKey = rawKey.replacingOccurrences(of: "\\n", with: "\n")
        let tokenManager = try ServerToServerAuthManager(keyID: keyID, pemString: privateKey)

        return try CloudKitService(
            containerIdentifier: config.containerIdentifier,
            tokenManager: tokenManager,
            environment: config.environment,
            database: .public
        )
    }
    
    /// Create a CloudKitService with specific authentication method
    /// - Parameters:
    ///   - config: The base MistDemo configuration
    ///   - tokenManager: Specific token manager to use
    ///   - database: Target database (default: private)
    /// - Returns: A configured CloudKitService instance
    /// - Throws: CloudKitService initialization errors
    public static func create(
        from config: MistDemoConfig,
        tokenManager: any TokenManager,
        database: MistKit.Database = .private
    ) throws -> CloudKitService {
        return try CloudKitService(
            containerIdentifier: config.containerIdentifier,
            tokenManager: tokenManager,
            environment: config.environment,
            database: database
        )
    }
    
    /// Load private key content from file path
    /// - Parameter filePath: Optional path to private key file
    /// - Returns: Private key content or nil if file doesn't exist/can't be read
    private static func loadPrivateKeyFromFile(_ filePath: String?) -> String? {
        guard let filePath = filePath, !filePath.isEmpty else { return nil }
        
        do {
            return try String(contentsOfFile: filePath, encoding: .utf8)
        } catch {
            // Return nil instead of throwing to allow fallback to other auth methods
            return nil
        }
    }
}