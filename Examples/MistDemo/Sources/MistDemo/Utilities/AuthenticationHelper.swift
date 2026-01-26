//
//  AuthenticationHelper.swift
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

/// Helper utilities for managing CloudKit authentication
enum AuthenticationHelper {
    
    /// Result of authentication setup including token manager and selected database
    struct AuthenticationResult {
        let tokenManager: TokenManager
        let database: MistKit.Database
        let authMethod: String  // Description for logging
    }
    
    /// Creates appropriate TokenManager and determines database based on credentials
    /// - Parameters:
    ///   - apiToken: CloudKit API token (always required)
    ///   - webAuthToken: Web authentication token from Sign in with Apple
    ///   - keyID: Server-to-server key identifier
    ///   - privateKey: Server-to-server private key as string
    ///   - privateKeyFile: Path to server-to-server private key file
    ///   - databaseOverride: Optional database override ("public" or "private")
    /// - Returns: Authentication result with TokenManager and selected database
    /// - Throws: Error if credentials are invalid or missing
    static func setupAuthentication(
        apiToken: String,
        webAuthToken: String?,
        keyID: String?,
        privateKey: String?,
        privateKeyFile: String?,
        databaseOverride: String? = nil
    ) async throws -> AuthenticationResult {
        
        // Check for server-to-server authentication
        if let keyID = keyID {
            // Server-to-server always uses public database
            let database = MistKit.Database.public
            
            // Check for invalid override
            if let override = databaseOverride, override == "private" {
                throw AuthenticationError.serverToServerRequiresPublicDatabase
            }
            
            let manager = try await createServerToServerManager(
                keyID: keyID,
                privateKey: privateKey,
                privateKeyFile: privateKeyFile
            )
            
            return AuthenticationResult(
                tokenManager: manager,
                database: database,
                authMethod: "🔐 Server-to-server authentication (public database only)"
            )
        }
        
        // Web authentication
        if let webAuthToken = webAuthToken, !webAuthToken.isEmpty {
            // With web auth token, default to private but allow override
            let database: MistKit.Database
            if let override = databaseOverride {
                database = override == "public" ? .public : .private
            } else {
                database = .private  // Default to private when web auth is available
            }
            
            let manager = try await createWebAuthManager(
                apiToken: apiToken,
                webAuthToken: webAuthToken
            )
            
            return AuthenticationResult(
                tokenManager: manager,
                database: database,
                authMethod: "🌐 Web authentication (\(database) database)"
            )
        }
        
        // API-only authentication (no web token)
        // Can only use public database
        let database = MistKit.Database.public
        
        // Check for invalid override
        if let override = databaseOverride, override == "private" {
            throw AuthenticationError.privateRequiresWebAuth
        }
        
        let manager = APITokenManager(apiToken: apiToken)
        
        // Validate credentials
        let isValid = try await manager.validateCredentials()
        guard isValid else {
            throw AuthenticationError.invalidAPIToken
        }
        
        return AuthenticationResult(
            tokenManager: manager,
            database: database,
            authMethod: "🔑 API-only authentication (public database only)"
        )
    }
    
    /// Creates a ServerToServerAuthManager
    private static func createServerToServerManager(
        keyID: String,
        privateKey: String?,
        privateKeyFile: String?
    ) async throws -> TokenManager {
        
        // Get the private key PEM string
        let privateKeyPEM: String
        if let keyFile = privateKeyFile {
            do {
                privateKeyPEM = try String(contentsOfFile: keyFile, encoding: .utf8)
            } catch {
                throw AuthenticationError.failedToReadPrivateKeyFile(keyFile, error)
            }
        } else if let key = privateKey {
            privateKeyPEM = key
        } else {
            throw AuthenticationError.missingPrivateKey
        }
        
        // Check platform availability
        guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
            throw AuthenticationError.serverToServerNotSupported
        }
        
        // Create and validate the manager
        let manager = try ServerToServerAuthManager(
            keyID: keyID,
            pemString: privateKeyPEM
        )
        
        // Validate credentials
        let isValid = try await manager.validateCredentials()
        guard isValid else {
            throw AuthenticationError.invalidServerToServerCredentials
        }
        
        return manager
    }
    
    /// Creates a WebAuthTokenManager
    private static func createWebAuthManager(
        apiToken: String,
        webAuthToken: String
    ) async throws -> TokenManager {
        let manager = WebAuthTokenManager(
            apiToken: apiToken,
            webAuthToken: webAuthToken
        )
        
        // Validate credentials
        let isValid = try await manager.validateCredentials()
        guard isValid else {
            throw AuthenticationError.invalidWebAuthCredentials
        }
        
        return manager
    }
    
    /// Resolves API token from option or environment variable
    static func resolveAPIToken(_ apiToken: String) -> String {
        apiToken.isEmpty ?
            EnvironmentConfig.getOptional(EnvironmentConfig.Keys.cloudKitAPIToken) ?? "" :
            apiToken
    }
    
    /// Resolves web auth token from option or environment variable
    static func resolveWebAuthToken(_ webAuthToken: String) -> String? {
        let token = webAuthToken.isEmpty ?
            ProcessInfo.processInfo.environment["CLOUDKIT_WEBAUTH_TOKEN"] ?? "" :
            webAuthToken
        return token.isEmpty ? nil : token
    }
}

/// Errors that can occur during authentication setup
enum AuthenticationError: LocalizedError {
    case serverToServerRequiresPublicDatabase
    case failedToReadPrivateKeyFile(String, any Error)
    case missingPrivateKey
    case serverToServerNotSupported
    case invalidServerToServerCredentials
    case privateRequiresWebAuth
    case invalidWebAuthCredentials
    case invalidAPIToken
    case noValidAuthenticationMethod
    
    var errorDescription: String? {
        switch self {
        case .serverToServerRequiresPublicDatabase:
            return "Server-to-server authentication only supports public database access"
        case .failedToReadPrivateKeyFile(let path, let error):
            return "Failed to read private key file at \(path): \(error.localizedDescription)"
        case .missingPrivateKey:
            return "Server-to-server authentication requires a private key (use --private-key or --private-key-file)"
        case .serverToServerNotSupported:
            return "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
        case .invalidServerToServerCredentials:
            return "Server-to-server credentials validation failed. Check your key ID and private key."
        case .privateRequiresWebAuth:
            return "Private database access requires web authentication token. Use 'mistdemo auth' to sign in with Apple ID or provide --web-auth-token"
        case .invalidWebAuthCredentials:
            return "Web authentication credentials validation failed. Token may be expired."
        case .invalidAPIToken:
            return "API token validation failed. Check your CloudKit API token."
        case .noValidAuthenticationMethod:
            return "No valid authentication method could be determined from provided credentials"
        }
    }
}