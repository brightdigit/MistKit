//
//  BaseTokenManager.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Base class providing common functionality for all token managers
/// Consolidates duplicate code patterns across different authentication methods
@available(*, deprecated, message: "Use protocol-based approach instead")
internal final class BaseTokenManager: TokenManager, @unchecked Sendable {
  internal let storage: (any TokenStorage)?
  
  internal init(storage: (any TokenStorage)? = nil) {
    self.storage = storage
  }
  
  // MARK: - TokenManager Protocol
  
  public var hasCredentials: Bool {
    get async {
      await validateCredentialsInternal()
    }
  }
  
  public func validateCredentials() async throws -> Bool {
    await validateCredentialsInternal()
  }
  
  public func getCurrentCredentials() async throws -> TokenCredentials? {
    _ = try await validateCredentials()
    return try await createCredentials()
  }
  
  
  // MARK: - Internal Methods to Override
  
  /// Internal validation logic - override in subclasses
  internal func validateCredentialsInternal() async -> Bool {
    true
  }
  
  /// Create credentials - override in subclasses
  internal func createCredentials() async throws -> TokenCredentials? {
    nil
  }
  
  // MARK: - Common Validation Helpers
  
  /// Validates API token format using regex
  /// - Parameter apiToken: The API token to validate
  /// - Throws: TokenManagerError if validation fails
  internal static func validateAPITokenFormat(_ apiToken: String) throws {
    guard !apiToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "API token is empty")
    }
    
    let regex = NSRegularExpression.apiTokenRegex
    let matches = regex.matches(in: apiToken)
    
    guard !matches.isEmpty else {
      throw TokenManagerError.invalidCredentials(
        reason: "API token format is invalid (expected 64-character hex string)"
      )
    }
  }
  
  /// Validates web auth token format
  /// - Parameter webToken: The web auth token to validate
  /// - Throws: TokenManagerError if validation fails
  internal static func validateWebAuthTokenFormat(_ webToken: String) throws {
    guard !webToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "Web auth token is empty")
    }
    
    guard webToken.count >= 10 else {
      throw TokenManagerError.invalidCredentials(
        reason: "Web auth token appears to be too short"
      )
    }
  }
  
  /// Validates key ID format
  /// - Parameter keyID: The key ID to validate
  /// - Throws: TokenManagerError if validation fails
  internal static func validateKeyIDFormat(_ keyID: String) throws {
    guard !keyID.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "Key ID is empty")
    }
    
    let regex = NSRegularExpression.keyIDRegex
    let matches = regex.matches(in: keyID)
    
    guard !matches.isEmpty else {
      throw TokenManagerError.invalidCredentials(
        reason: "Key ID format is invalid (expected 64-character hex string)"
      )
    }
  }
}
