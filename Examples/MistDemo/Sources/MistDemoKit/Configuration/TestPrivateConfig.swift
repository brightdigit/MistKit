//
//  TestPrivateConfig.swift
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

public import ConfigKeyKit
internal import MistKit

/// Configuration for test-private command (private database).
public struct TestPrivateConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The number of records to create during testing.
  public let recordCount: Int
  /// The asset size in kilobytes for upload testing.
  public let assetSizeKB: Int
  /// Whether to skip cleanup after testing.
  public let skipCleanup: Bool
  /// Whether to enable verbose output.
  public let verbose: Bool
  /// Optional email used by the lookup-users-by-email phase. Must belong to
  /// an iCloud account discoverable to the caller; otherwise the phase skips.
  public let lookupEmail: String?
  /// Optional share short GUID used by the resolve/accept sharing phases.
  /// Unused by `PrivateDatabaseTest` today (those phases are public-DB-only)
  /// but kept for symmetry with `TestPublicConfig`.
  public let shareShortGUID: String?
  /// Web-auth token for the **sharee** account
  /// (`CLOUDKIT_SHAREE_WEB_AUTH_TOKEN`). Required with ``shareeEmail`` for
  /// the create→accept share roundtrip. The primary `CLOUDKIT_WEB_AUTH_TOKEN`
  /// remains the **sharer**. Obtain both via `mistdemo auth-tokens`.
  public let shareeWebAuthToken: String
  /// iCloud email of the sharee (`CLOUDKIT_SHAREE_EMAIL`), used as the
  /// invitee lookup info when creating the share.
  public let shareeEmail: String

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    recordCount: Int = 10,
    assetSizeKB: Int = 100,
    skipCleanup: Bool = false,
    verbose: Bool = false,
    lookupEmail: String? = nil,
    shareShortGUID: String? = nil,
    shareeWebAuthToken: String,
    shareeEmail: String
  ) {
    self.base = base
    self.recordCount = recordCount
    self.assetSizeKB = assetSizeKB
    self.skipCleanup = skipCleanup
    self.verbose = verbose
    self.lookupEmail = lookupEmail
    self.shareShortGUID = shareShortGUID
    self.shareeWebAuthToken = shareeWebAuthToken
    self.shareeEmail = shareeEmail
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let parsedBase: MistDemoConfig
    if let base {
      parsedBase = base
    } else {
      parsedBase = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }
    // test-private's identity is "private database test" — pin
    // the database regardless of any --database flag the user supplied.
    let baseConfig = parsedBase.with(database: .private)

    guard
      let webAuthToken = baseConfig.webAuthToken,
      !webAuthToken.isEmpty
    else {
      throw ConfigurationError.missingRequired(
        "web.auth.token",
        suggestion:
          "Provide via CLOUDKIT_WEB_AUTH_TOKEN or run `mistdemo auth-tokens`"
      )
    }

    guard
      let shareeWebAuthToken = configuration.read(MistDemoKeys.Auth.shareeWebAuthToken),
      !shareeWebAuthToken.isEmpty
    else {
      throw ConfigurationError.missingRequired(
        "sharee.web.auth.token",
        suggestion:
          "Provide via CLOUDKIT_SHAREE_WEB_AUTH_TOKEN or run `mistdemo auth-tokens`"
      )
    }

    guard
      let shareeEmail = configuration.read(MistDemoKeys.Auth.shareeEmail),
      !shareeEmail.isEmpty
    else {
      throw ConfigurationError.missingRequired(
        "sharee.email",
        suggestion:
          "Provide via CLOUDKIT_SHAREE_EMAIL or `mistdemo auth-tokens --sharee-email …`"
      )
    }

    let recordCount =
      configuration.read(MistDemoKeys.Integration.recordCount)
    let assetSizeKB =
      configuration.read(MistDemoKeys.Integration.assetSize)
    let skipCleanup =
      configuration.read(MistDemoKeys.Integration.skipCleanup)
    let verbose =
      configuration.read(MistDemoKeys.Output.verbose)
    let lookupEmail = configuration.read(MistDemoKeys.Integration.lookupEmail)
    let shareShortGUID = configuration.read(MistDemoKeys.Integration.shareShortGUID)

    self.init(
      base: baseConfig,
      recordCount: recordCount,
      assetSizeKB: assetSizeKB,
      skipCleanup: skipCleanup,
      verbose: verbose,
      lookupEmail: lookupEmail,
      shareShortGUID: shareShortGUID,
      shareeWebAuthToken: shareeWebAuthToken,
      shareeEmail: shareeEmail
    )
  }
}
