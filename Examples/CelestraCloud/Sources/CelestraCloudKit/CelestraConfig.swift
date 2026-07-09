//
//  CelestraConfig.swift
//  CelestraCloud
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

// MARK: - Shared Configuration

/// Shared configuration helper for creating CloudKit service
public enum CelestraConfig {
  /// Create CloudKit service from validated configuration
  public static func createCloudKitService(from config: ValidatedCloudKitConfiguration) throws
    -> CloudKitService
  {
    // Read private key from file
    let privateKeyPEM = try String(contentsOfFile: config.privateKeyPath, encoding: .utf8)

    // Create token manager for server-to-server authentication
    let tokenManager = try ServerToServerAuthManager(
      keyID: config.keyID,
      pemString: privateKeyPEM
    )

    // Create and return CloudKit service
    return CloudKitService(
      containerIdentifier: config.containerID,
      tokenManager: tokenManager,
      environment: config.environment
    )
  }
}
