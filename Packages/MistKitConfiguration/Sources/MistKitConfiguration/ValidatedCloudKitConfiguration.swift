//
//  ValidatedCloudKitConfiguration.swift
//  MistKitConfiguration
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

internal import Foundation
public import MistKit

/// CloudKit credentials that have passed presence *and* format validation.
///
/// The initializer is throwing and runs ``KeyIDValidator`` — and ``PEMValidator`` for an
/// inline key — so there is no way to hold a value of this type whose credentials skipped
/// format checking. That property is what lets callers drop their own hand-rolled
/// validation before constructing a service.
public struct ValidatedCloudKitConfiguration: Sendable {
  /// The CloudKit container identifier.
  public let containerID: String
  /// The server-to-server key ID.
  public let keyID: String
  /// The resolved signing key, inline or a path to a `.pem` file.
  public let privateKey: PrivateKeyMaterial
  /// The CloudKit environment.
  public let environment: MistKit.Environment

  /// Creates a validated configuration from already-resolved values.
  ///
  /// - Parameters:
  ///   - containerID: The CloudKit container identifier.
  ///   - keyID: The server-to-server key ID; must be 64 hex characters.
  ///   - privateKey: The signing key; inline PEM is validated, a file path is not read.
  ///   - environment: The CloudKit environment.
  /// - Throws: ``CloudKitConfigurationError/invalidKeyID(_:)`` or
  ///   ``CloudKitConfigurationError/invalidPrivateKey(_:)``.
  public init(
    containerID: String,
    keyID: String,
    privateKey: PrivateKeyMaterial,
    environment: MistKit.Environment
  ) throws(CloudKitConfigurationError) {
    do {
      try KeyIDValidator.validate(keyID)
    } catch {
      throw .invalidKeyID(error)
    }
    if case .raw(let pem) = privateKey {
      do {
        try PEMValidator.validate(pem)
      } catch {
        throw .invalidPrivateKey(error)
      }
    }

    self.containerID = containerID
    self.keyID = keyID
    self.privateKey = privateKey
    self.environment = environment
  }
}

extension ValidatedCloudKitConfiguration {
  /// Builds a `CloudKitService` signing with these server-to-server credentials.
  ///
  /// `PrivateKeyMaterial` defers reading a `.file(path:)` key until the credentials are
  /// consumed, so this performs no file IO.
  ///
  /// - Returns: A configured service.
  /// - Throws: `CredentialsValidationError` if MistKit rejects the credentials.
  public func makeCloudKitService() throws -> CloudKitService {
    CloudKitService(
      containerIdentifier: containerID,
      credentials: try Credentials(
        serverToServer: ServerToServerCredentials(keyID: keyID, privateKey: privateKey)
      ),
      environment: environment
    )
  }
}
