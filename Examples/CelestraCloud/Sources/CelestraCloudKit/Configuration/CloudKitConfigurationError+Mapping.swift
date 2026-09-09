//
//  CloudKitConfigurationError+Mapping.swift
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

internal import ConfigKeyKit
public import MistKitConfiguration

extension CloudKitConfigurationError {
  /// Maps a package error onto Celestra's presentation wording and key names.
  ///
  /// - Parameter keys: Key group used to name the flag or environment variable at fault.
  /// - Returns: A ``ConfigurationError`` ready to surface to the user.
  public func map(keys: CloudKitConfigurationKeys) -> ConfigurationError {
    switch self {
    case .missing(.containerID):
      ConfigurationError(
        "CloudKit container ID must be non-empty",
        key: keys.containerID.base
      )
    case .missing(.keyID):
      ConfigurationError(
        "CloudKit key ID must be non-empty",
        key: keys.keyID.base
      )
    case .missing(.privateKey), .missing(.privateKeyPath):
      ConfigurationError(
        "Either CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH must be provided",
        key: keys.privateKey.base
      )
    case .missing(.environment):
      ConfigurationError(
        "CloudKit environment must be 'development' or 'production'",
        key: keys.environment.base
      )
    case .invalidKeyID(let failure):
      ConfigurationError(
        "Invalid CloudKit Server-to-Server Key ID: \(String(describing: failure))",
        key: keys.keyID.base
      )
    case .invalidPrivateKey(let failure):
      ConfigurationError(
        "Invalid PEM format: \(String(describing: failure))",
        key: keys.privateKey.base
      )
    case .unrecognizedEnvironment(let raw):
      ConfigurationError(
        "Invalid CLOUDKIT_ENVIRONMENT: '\(raw)'. Must be 'development' or 'production'",
        key: keys.environment.base
      )
    }
  }
}

extension CloudKitConfiguration {
  /// Validates credentials, mapping package errors into Celestra ``ConfigurationError``.
  public func validatedForCelestra() throws -> ValidatedCloudKitConfiguration {
    do {
      return try validated()
    } catch {
      throw error.map(keys: ConfigurationKeys.cloudKit)
    }
  }
}
