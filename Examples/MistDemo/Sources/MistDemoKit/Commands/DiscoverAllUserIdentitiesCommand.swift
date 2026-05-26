//
//  DiscoverAllUserIdentitiesCommand.swift
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

/// Command that discovers user identities for a set of email addresses using
/// the auto-chunking `discoverAllUserIdentities(lookupInfos:)` convenience
/// (issue #307).
public struct DiscoverAllUserIdentitiesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = DiscoverConfig
  /// The command name.
  public static let commandName = "discover-all"
  /// The command abstract.
  public static let abstract =
    "Discover user identities, auto-chunking large inputs (discoverAllUserIdentities)"
  /// The command help text.
  public static let helpText = """
    DISCOVER-ALL - Discover user identities, auto-chunking past CloudKit's 200/request cap

    USAGE:
      mistdemo discover-all --discover-emails <list> [options]

    INPUT (choose one):
      --discover-emails <list>       Comma-separated email addresses
      --stdin                        Read one email per line from stdin

    OPTIONS:
      --batch-size <n>               Items per request (default 200, clamped 1...200).
                                     Set small (e.g. 1) to force multiple requests.
      --output-format <format>       Output format (json, table, csv, yaml)

    NOTES:
      - Requires API + web-auth credentials; the endpoint is pinned to the
        public database, so the --database flag does not apply.
      - Each email is sent as a lookup info; CloudKit only returns identities
        for accounts discoverable to the caller.
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

    let effectiveBatchSize = min(
      max(config.batchSize, 1),
      CloudKitService.maxRecordsPerRequest
    )
    let batches = (config.emails.count + effectiveBatchSize - 1) / effectiveBatchSize
    let note =
      "discover-all: \(config.emails.count) lookup(s), batchSize \(config.batchSize) "
      + "→ \(batches) request(s)\n"
    FileHandle.standardError.write(Data(note.utf8))

    let lookupInfos = config.emails.map { UserIdentityLookupInfo(emailAddress: $0) }
    let identities = try await service.discoverAllUserIdentities(
      lookupInfos: lookupInfos,
      batchSize: config.batchSize
    )
    try await outputResults(identities, format: config.output)
  }
}
