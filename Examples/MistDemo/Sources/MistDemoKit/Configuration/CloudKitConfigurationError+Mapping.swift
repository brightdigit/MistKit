//
//  CloudKitConfigurationError+Mapping.swift
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

internal import MistKitConfiguration

extension CloudKitConfigurationError {
  /// Maps a package error onto MistDemo's existing ``ConfigurationError`` cases.
  internal func map() -> ConfigurationError {
    switch self {
    case .missing(.containerID):
      .missingRequired(
        "container.id",
        suggestion: "Set CLOUDKIT_CONTAINER_ID or --cloudkit-container-id."
      )
    case .missing(.keyID):
      .missingRequired(
        "key.id",
        suggestion: "Set CLOUDKIT_KEY_ID or --cloudkit-key-id."
      )
    case .missing(.privateKey), .missing(.privateKeyPath):
      .missingRequired(
        "private.key",
        suggestion: "Set CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH."
      )
    case .missing(.environment):
      .invalidEnvironment("")
    case .invalidKeyID:
      .missingRequired(
        "key.id",
        suggestion: "Provide a 64-character hexadecimal CloudKit Server-to-Server Key ID."
      )
    case .invalidPrivateKey:
      .missingRequired(
        "private.key",
        suggestion:
          "Provide a PEM-encoded private key via CLOUDKIT_PRIVATE_KEY or CLOUDKIT_PRIVATE_KEY_PATH."
      )
    case .unrecognizedEnvironment(let raw):
      .invalidEnvironment(raw)
    }
  }
}
