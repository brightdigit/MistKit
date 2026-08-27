//
//  ResolveConfig.swift
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
internal import Foundation

/// Configuration for the `resolve` command (`records/resolve`).
public struct ResolveConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The short GUIDs to resolve, in request order.
  public let shortGUIDs: [String]
  /// Whether to ask CloudKit to include the root record alongside each
  /// share. When `nil`, CloudKit applies its own default.
  public let fetchRootRecord: Bool?
  /// Field names limiting the root record payload, when fetched.
  public let fields: [String]?
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    shortGUIDs: [String],
    fetchRootRecord: Bool? = nil,
    fields: [String]? = nil,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.shortGUIDs = shortGUIDs
    self.fetchRootRecord = fetchRootRecord
    self.fields = fields
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let outputString =
      configuration.string(
        forKey: MistDemoConstants.ConfigKeys.outputFormat,
        default: "json"
      ) ?? "json"
    let output = OutputFormat(rawValue: outputString) ?? .json

    let fetchRootRecord = configuration.optionalBool(
      forKey: "fetch.root.record"
    )
    let fields = configuration.commaSeparatedList(
      forKey: MistDemoConstants.ConfigKeys.fields
    )

    let shortGUIDs = Self.parseShortGUIDs(from: configuration)
    guard !shortGUIDs.isEmpty else {
      throw ResolveError.shortGUIDRequired
    }

    self.init(
      base: baseConfig,
      shortGUIDs: shortGUIDs,
      fetchRootRecord: fetchRootRecord,
      fields: fields,
      output: output
    )
  }

  /// Parse short GUIDs from `--short-guid` (preferred, comma-separated) or
  /// `--share-url` (comma-separated share URLs, each reduced to its last
  /// path component — the short GUID value CloudKit's share webpage URLs
  /// carry, e.g. `https://www.icloud.com/share/abc123` → `abc123`).
  internal static func parseShortGUIDs(
    from configuration: MistDemoConfiguration
  ) -> [String] {
    if let fromGUIDs = configuration.commaSeparatedList(forKey: "short.guid"),
      !fromGUIDs.isEmpty
    {
      return fromGUIDs
    }

    guard let shareURLs = configuration.commaSeparatedList(forKey: "share.url")
    else {
      return []
    }
    return shareURLs.compactMap(parseShortGUID(fromShareURL:))
  }

  /// Extract the short GUID value from a share URL's last path component.
  internal static func parseShortGUID(fromShareURL shareURL: String) -> String? {
    guard let url = URL(string: shareURL) else { return nil }
    let value = url.lastPathComponent
    return value.isEmpty ? nil : value
  }
}
