//
//  ServerToServerAuthManager+RequestSigning.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Crypto
public import Foundation

// MARK: - Request Signing Methods

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthManager {
  /// Signs a CloudKit Web Services request
  /// - Parameters:
  ///   - requestBody: The HTTP request body (for POST requests)
  ///   - webServiceURL: The full CloudKit Web Services URL
  ///   - date: The request date (defaults to current date)
  /// - Returns: Signature components for CloudKit headers
  public func signRequest(
    requestBody: Data?,
    webServiceURL: String,
    date: Date = Date()
  ) throws -> RequestSignature {
    // Create the signature payload according to Apple's CloudKit specification:
    // [Current Date]:[Base64 Body Hash]:[Web Service URL Subpath]
    // Apple requires ISO8601 format without milliseconds (e.g., 2016-01-25T22:15:43Z)
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
    let iso8601Date = formatter.string(from: date)

    // Calculate SHA-256 hash of request body, then base64 encode (per Apple docs)
    let bodyHash: String
    if let requestBody = requestBody {
      let hash = SHA256.hash(data: requestBody)
      bodyHash = Data(hash).base64EncodedString()
    } else {
      bodyHash = ""
    }

    let signaturePayload = "\(iso8601Date):\(bodyHash):\(webServiceURL)"

    // Debug output for troubleshooting
    print("🔍 Debug - Signature Payload:")
    print("   Date: \(iso8601Date)")
    print("   Body Hash: \(bodyHash)")
    print("   Web Service URL: \(webServiceURL)")
    print("   Full Payload: \(signaturePayload)")

    guard let payloadData = signaturePayload.data(using: .utf8) else {
      throw TokenManagerError.internalError(reason: "Failed to encode signature payload")
    }

    // Create ECDSA signature
    let signature = try privateKey().signature(for: payloadData)
    let signatureBase64 = signature.derRepresentation.base64EncodedString()

    return RequestSignature(
      keyID: keyID,
      date: iso8601Date,
      signature: signatureBase64
    )
  }

  /// The key identifier
  public var keyIdentifier: String {
    keyID
  }

  /// Returns the public key for verification purposes
  public var publicKey: P256.Signing.PublicKey {
    get throws {
      try privateKey().publicKey
    }
  }

  /// Creates credentials with additional metadata
  /// - Parameter metadata: Additional metadata to include
  /// - Returns: TokenCredentials with metadata
  public func credentialsWithMetadata(_ metadata: [String: String]) throws -> TokenCredentials {
    try TokenCredentials(
      method: .serverToServer(keyID: keyID, privateKey: privateKey().rawRepresentation),
      metadata: metadata
    )
  }

  /// Creates new credentials with rotated key (for key rotation)
  /// - Parameter newPrivateKey: The new private key
  /// - Returns: New TokenCredentials with updated key
  /// - Note: This creates new credentials but doesn't update the manager's internal key
  public func credentialsWithRotatedKey(to newPrivateKey: P256.Signing.PrivateKey)
    -> TokenCredentials
  {
    // Note: This would typically require updating the keyID as well in a real rotation
    TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: newPrivateKey.rawRepresentation
    )
  }

  /// Creates a MistKitConfiguration for server-to-server authentication
  /// This automatically configures the public database as required for server-to-server auth
  /// - Parameters:
  ///   - container: The CloudKit container identifier
  ///   - environment: The CloudKit environment
  /// - Returns: A properly configured MistKitConfiguration for server-to-server use
  public static func configuration(
    container: String,
    environment: Environment
  ) -> MistKitConfiguration {
    MistKitConfiguration.serverToServer(
      container: container,
      environment: environment
    )
  }
}
