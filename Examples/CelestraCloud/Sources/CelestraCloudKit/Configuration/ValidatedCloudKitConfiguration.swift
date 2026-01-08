//
//  ValidatedCloudKitConfiguration.swift
//  CelestraCloud
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

public import Foundation
public import MistKit

/// Validated CloudKit configuration with all required fields
public struct ValidatedCloudKitConfiguration: Sendable {
  /// CloudKit container identifier (validated non-empty)
  public let containerID: String

  /// Server-to-Server authentication key ID (validated non-empty)
  public let keyID: String

  /// Absolute path to PEM-encoded private key file (validated non-empty)
  public let privateKeyPath: String

  /// CloudKit environment (development or production)
  public let environment: MistKit.Environment

  /// Initialize validated CloudKit configuration
  /// - Parameters:
  ///   - containerID: CloudKit container identifier
  ///   - keyID: Server-to-Server authentication key ID
  ///   - privateKeyPath: Absolute path to PEM-encoded private key file
  ///   - environment: CloudKit environment
  public init(
    containerID: String,
    keyID: String,
    privateKeyPath: String,
    environment: MistKit.Environment
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.environment = environment
  }
}
