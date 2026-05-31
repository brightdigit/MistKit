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

/// Stub command for `records/resolve`. Resolves a share URL or record
/// reference to a CloudKit record. The MistKit Swift wrapper is tracked
/// in #41; until that lands, this command prints the standard pending
/// banner and exits 0 so the `--help` shape is discoverable today.
public struct ResolveCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = ResolveConfig
  /// The command name.
  public static let commandName = "resolve"
  /// The command abstract.
  public static let abstract = "Resolve a share URL or record reference (pending #41)"
  /// The command help text.
  public static let helpText = """
    RESOLVE - Resolve a share URL or record reference

    USAGE:
      mistdemo resolve --share-url <url> [options]
      mistdemo resolve --record-name <name> [options]

    INPUT (choose one):
      --share-url <url>          Share URL to resolve
      --record-name <name>       Record name to resolve

    OPTIONS:
      --database <type>          Database to target
      --output-format <format>   Output format (json, table, csv, yaml)

    STATUS:
      Not yet implemented — pending MistKit support, tracked in #41.
    """

  private let config: ResolveConfig

  /// Creates a new instance.
  public init(config: ResolveConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    PendingStub.printPending(endpoint: "records/resolve", trackingIssue: 41)
  }
}
