//
//  TokenValidation.swift
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

#if canImport(Foundation)
import Foundation
#endif

/// Common token validation utilities to reduce code duplication
public enum TokenValidation {
  
  /// Validates API token format using regex
  /// - Parameter apiToken: The API token to validate
  /// - Throws: TokenManagerError if validation fails
  public static func validateAPITokenFormat(_ apiToken: String) throws {
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
  public static func validateWebAuthTokenFormat(_ webToken: String) throws {
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
  public static func validateKeyIDFormat(_ keyID: String) throws {
    guard !keyID.isEmpty else {
      throw TokenManagerError.invalidCredentials(reason: "Key ID is empty")
    }
    
    guard keyID.count >= 8 else {
      throw TokenManagerError.invalidCredentials(
        reason: "Key ID appears to be too short (minimum 8 characters)"
      )
    }
  }
}
