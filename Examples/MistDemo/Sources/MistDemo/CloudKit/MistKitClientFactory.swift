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
    
    /// Create a CloudKitService for the given database, choosing auth method automatically.
    ///
    /// - `.public`: requires `CLOUDKIT_KEY_ID` + `CLOUDKIT_PRIVATE_KEY[_FILE]`
    /// - `.private` / `.shared`: requires `CLOUDKIT_API_TOKEN` + `CLOUDKIT_WEB_AUTH_TOKEN`
    /// - Parameters:
    ///   - database: Target database
    ///   - config: The base MistDemo configuration
    /// - Throws: ConfigurationError if required credentials are missing
    public static func create(_ database: MistKit.Database, from config: MistDemoConfig) throws -> CloudKitService {
        let tokenManager: any TokenManager
        switch database {
        case .public:
            guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
                throw ConfigurationError.unsupportedPlatform(
                    "Public database access requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
                )
            }
            tokenManager = try ServerToServerAuthManager(from: config)
        case .private, .shared:
            tokenManager = try WebAuthTokenManager(from: config)
        }
        return try CloudKitService(
            containerIdentifier: config.containerIdentifier,
            tokenManager: tokenManager,
            environment: config.environment,
            database: database
        )
    }

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
}

extension WebAuthTokenManager {
    fileprivate convenience init(from config: MistDemoConfig) throws {
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
        self.init(apiToken: apiToken, webAuthToken: webAuthToken)
    }
}

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthManager {
    fileprivate convenience init(from config: MistDemoConfig) throws {
        guard let keyID = config.keyID, !keyID.isEmpty else {
            throw ConfigurationError.missingRequired("key.id",
                suggestion: "Provide via CLOUDKIT_KEY_ID environment variable")
        }
        guard let rawKey = config.privateKey ?? Self.loadPrivateKeyFromFile(config.privateKeyFile),
              !rawKey.isEmpty else {
            throw ConfigurationError.missingRequired("private.key",
                suggestion: "Provide via CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH")
        }
        try self.init(keyID: keyID, pemString: rawKey.replacingOccurrences(of: "\\n", with: "\n"))
    }

    private static func loadPrivateKeyFromFile(_ filePath: String?) -> String? {
        guard let filePath, !filePath.isEmpty else { return nil }
        return try? String(contentsOfFile: filePath, encoding: .utf8)
    }
}