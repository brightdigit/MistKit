//
//  CloudKitConfiguration.swift
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
internal import MistKit

/// Raw CloudKit server-to-server settings, exactly as supplied.
///
/// Every field is optional and unparsed: this type is the output of *reading* a
/// configuration source and performs no validation, which is what lets reading itself be
/// non-throwing and composable into any application's own loader. Call ``validated()`` to
/// resolve and check it.
///
/// `environment` stays a `String?` rather than a `MistKit.Environment` so that
/// "unspecified" remains distinguishable from "explicitly development", and so an
/// unrecognized value fails at validation rather than at read time.
public struct CloudKitConfiguration: Sendable {
  /// CloudKit container identifier, e.g. `iCloud.com.example.App`.
  public var containerID: String?
  /// Server-to-server key ID from the CloudKit Dashboard.
  public var keyID: String?
  /// Path to a PEM-encoded private key file.
  public var privateKeyPath: String?
  /// Inline PEM private key, for environments where writing a file is inconvenient.
  public var privateKey: String?
  /// Unparsed CloudKit environment name; `nil` means unspecified.
  public var environment: String?

  /// Creates a raw configuration.
  ///
  /// - Parameters:
  ///   - containerID: CloudKit container identifier.
  ///   - keyID: Server-to-server key ID.
  ///   - privateKeyPath: Path to a PEM private key file.
  ///   - privateKey: Inline PEM private key.
  ///   - environment: Unparsed environment name.
  public init(
    containerID: String? = nil,
    keyID: String? = nil,
    privateKeyPath: String? = nil,
    privateKey: String? = nil,
    environment: String? = nil
  ) {
    self.containerID = containerID
    self.keyID = keyID
    self.privateKeyPath = privateKeyPath
    self.privateKey = privateKey
    self.environment = environment
  }

  /// Resolves and checks every field, failing closed on anything missing, empty, or
  /// unparseable.
  ///
  /// Presence is checked before format, so a configuration with both a malformed key ID
  /// and no private key reports ``CloudKitConfigurationError/missing(_:)`` first.
  /// An inline ``privateKey`` takes precedence over ``privateKeyPath``.
  ///
  /// - Returns: A validated configuration.
  /// - Throws: ``CloudKitConfigurationError``.
  public func validated() throws(CloudKitConfigurationError) -> ValidatedCloudKitConfiguration {
    guard let containerID, !containerID.isEmpty else {
      throw .missing(.containerID)
    }
    guard let keyID, !keyID.isEmpty else {
      throw .missing(.keyID)
    }

    let trimmedKey = privateKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let trimmedPath = privateKeyPath?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let material: PrivateKeyMaterial
    if !trimmedKey.isEmpty {
      material = .raw(trimmedKey)
    } else if !trimmedPath.isEmpty {
      material = .file(path: trimmedPath)
    } else {
      throw .missing(.privateKey)
    }

    let rawEnvironment = (environment ?? MistKit.Environment.development.rawValue)
      .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let parsed = MistKit.Environment(caseInsensitive: rawEnvironment) else {
      throw .unrecognizedEnvironment(environment ?? "")
    }

    return try ValidatedCloudKitConfiguration(
      containerID: containerID,
      keyID: keyID,
      privateKey: material,
      environment: parsed
    )
  }
}
