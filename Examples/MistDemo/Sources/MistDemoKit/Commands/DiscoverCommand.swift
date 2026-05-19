//
//  DiscoverCommand.swift
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

internal import Foundation
internal import MistKit

/// Command that discovers user identities by email address.
public struct DiscoverCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = DiscoverConfig
  /// The command name.
  public static let commandName = "discover"
  /// The command abstract.
  public static let abstract = "Discover user identities by email"
  /// The command help text.
  public static let helpText = """
    DISCOVER - Discover user identities by email

    USAGE:
      mistdemo discover --discover-emails <list>
      cat emails.txt | mistdemo discover --stdin

    INPUT (choose one):
      --discover-emails <list>       Comma-separated email addresses
      --stdin                        Read one email per line from stdin

    OPTIONS:
      --output-format <format>       Output format (json, table, csv, yaml)

    NOTES:
      - Requires API + web-auth credentials. The underlying CloudKit
        endpoint is pinned to the public database; the database flag
        does not apply.
      - CloudKit only returns identities for accounts discoverable to
        the caller.
    """

  private let config: DiscoverConfig

  /// Creates a new instance.
  public init(config: DiscoverConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    guard !config.emails.isEmpty else {
      throw DiscoverError.emailsRequired
    }
    guard config.base.hasUserContextCredentials else {
      throw DiscoverError.webAuthRequired
    }

    let service = try MistKitClientFactory.create(for: config.base)
    let identities = try await service.lookupUsersByEmail(config.emails)
    try await outputResults(identities, format: config.output)
  }
}
