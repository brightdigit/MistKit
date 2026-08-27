//
//  ResolveCommand.swift
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

/// Command for `records/resolve`. Resolves share short GUIDs — the handle
/// carried by CloudKit share URLs — into the root record, the governing
/// `cloudKit.share` record, and the caller's participation in each share.
public struct ResolveCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = ResolveConfig
  /// The command name.
  public static let commandName = "resolve"
  /// The command abstract.
  public static let abstract = "Resolve share short GUIDs (records/resolve)"
  /// The command help text.
  public static let helpText = """
    RESOLVE - Resolve share short GUIDs

    USAGE:
      mistdemo resolve --short-guid <guid>[,<guid>...] [options]
      mistdemo resolve --share-url <url>[,<url>...] [options]

    INPUT (choose one):
      --short-guid <list>          Comma-separated short GUIDs
      --share-url <list>           Comma-separated share URLs — the short
                                    GUID is parsed from each URL's last path
                                    component (e.g. .../share/abc123 → abc123)

    OPTIONS:
      --fetch-root-record          Ask CloudKit to include the root record
      --fields <field1,field2,...> Restrict the root record's fields
      --output-format <format>     Output format (json, table, csv, yaml)

    EXAMPLES:
      mistdemo resolve --short-guid abc123
      mistdemo resolve --short-guid abc123,def456 --fetch-root-record
      mistdemo resolve --share-url https://www.icloud.com/share/abc123

    NOTES:
      Requires API + web-auth credentials — CloudKit pins records/resolve
      to the public database with web-auth regardless of --database.
    """

  private let config: ResolveConfig

  /// Creates a new instance.
  public init(config: ResolveConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    guard config.base.hasUserContextCredentials else {
      throw ResolveError.webAuthRequired
    }

    let service = try MistKitClientFactory.create(for: config.base)
    let shortGUIDs = config.shortGUIDs.map {
      ShortGUIDDictionary(
        value: $0,
        shouldFetchRootRecord: config.fetchRootRecord,
        rootRecordDesiredKeys: config.fields
      )
    }

    do {
      let results = try await service.resolveShares(shortGUIDs)
      printSummary(results)
      try await outputResults(results, format: config.output)
    } catch let error as ResolveError {
      throw error
    } catch {
      throw ResolveError.operationFailed(error.localizedDescription)
    }
  }

  private func printSummary(_ results: [ShareRecordInfo]) {
    print(
      "✅ Resolved \(results.count) share\(results.count == 1 ? "" : "s")"
    )
    for result in results {
      print("   - shortGUID: \(result.shortGUID.value)")
      print("     rootRecordName: \(result.rootRecordName ?? "-")")
      print(
        "     participantStatus: \(result.participantStatus?.rawValue ?? "-")"
      )
      print(
        "     participantPermission: "
          + "\(result.participantPermission?.rawValue ?? "-")"
      )
      if let zoneID = result.zoneID {
        print("     zoneID: \(zoneID.zoneName)")
      }
    }
  }
}
