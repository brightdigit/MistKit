//
//  DiscoverConfig.swift
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
public import MistKit

/// Configuration for the `discover` command (email lookup).
public struct DiscoverConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The email addresses to look up.
  public let emails: [String]
  /// Maximum items per request for the auto-chunking `discover-all` command
  /// (the plain `discover` command ignores it).
  public let batchSize: Int
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    emails: [String],
    batchSize: Int = CloudKitService.maxRecordsPerRequest,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.emails = emails
    self.batchSize = batchSize
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

    let emails = Self.parseEmails(from: configuration)

    let outputString =
      configuration.read(MistDemoKeys.Output.format)
    let output = OutputFormat(rawValue: outputString) ?? .json

    let batchSize =
      configuration.read(MistDemoKeys.Record.batchSize)

    self.init(
      base: baseConfig,
      emails: emails,
      batchSize: batchSize,
      output: output
    )
  }

  /// Parse emails from the `discover.emails` key (comma-separated) or stdin
  /// (one address per line) when `--stdin` is set.
  internal static func parseEmails(
    from configuration: MistDemoConfiguration
  ) -> [String] {
    if let raw = configuration.read(MistDemoKeys.Integration.discoverEmails),
      !raw.isEmpty
    {
      return
        raw
        .split(separator: ",")
        .map { String($0).trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    }

    if configuration.read(MistDemoKeys.Record.stdin) {
      let stdinData = FileHandle.standardInput.readDataToEndOfFile()
      guard let raw = String(data: stdinData, encoding: .utf8) else {
        return []
      }
      return
        raw
        .split(whereSeparator: { $0.isNewline })
        .map { String($0).trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
    }

    return []
  }
}
