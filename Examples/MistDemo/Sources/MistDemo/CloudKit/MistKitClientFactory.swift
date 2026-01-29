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
    
    /// Create a CloudKitService from MistDemo configuration
    /// - Parameter config: The base MistDemo configuration
    /// - Returns: A configured CloudKitService instance
    /// - Throws: ConfigurationError if required values are missing or invalid
    public static func create(from config: MistDemoConfig) throws -> CloudKitService {
        // Resolve API token
        let apiToken = config.resolvedApiToken()
        guard !apiToken.isEmpty else {
            throw ConfigurationError.missingRequired("api.token", 
                suggestion: "Provide via --api-token or CLOUDKIT_API_TOKEN environment variable")
        }
        
        // Determine the best token manager based on available credentials
        let tokenManager: any TokenManager
        
        if let webAuthToken = config.resolvedWebAuthToken(), !webAuthToken.isEmpty {
            // Use web authentication if available
            tokenManager = WebAuthTokenManager(apiToken: apiToken, webAuthToken: webAuthToken)
        } else if let keyID = config.keyID, 
                  let privateKey = config.privateKey ?? loadPrivateKeyFromFile(config.privateKeyFile),
                  !keyID.isEmpty, !privateKey.isEmpty {
            // Use server-to-server authentication if available
            if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                tokenManager = try ServerToServerAuthManager(keyID: keyID, pemString: privateKey)
            } else {
                throw ConfigurationError.unsupportedPlatform(
                    "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
                )
            }
        } else {
            // Fall back to API-only authentication
            tokenManager = APITokenManager(apiToken: apiToken)
        }
        
        // Create the CloudKitService
        return try CloudKitService(
            containerIdentifier: config.containerIdentifier,
            tokenManager: tokenManager,
            environment: config.environment,
            database: .private // Default to private database for most operations
        )
    }
    
    /// Create a CloudKitService for public database operations
    /// - Parameter config: The base MistDemo configuration
    /// - Returns: A configured CloudKitService instance for public database
    /// - Throws: ConfigurationError if required values are missing or invalid
    public static func createForPublicDatabase(from config: MistDemoConfig) throws -> CloudKitService {
        let apiToken = config.resolvedApiToken()
        guard !apiToken.isEmpty else {
            throw ConfigurationError.missingRequired("api.token",
                suggestion: "Provide via --api-token or CLOUDKIT_API_TOKEN environment variable")
        }
        
        // For public database, use API-only authentication
        let tokenManager = APITokenManager(apiToken: apiToken)
        
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