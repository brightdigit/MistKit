//
//  RereferenceAssetCommand.swift
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

/// Stub command for `assets/rereference`. Reuses an existing CloudKit asset
/// descriptor from one record on another, avoiding a second upload. The
/// MistKit Swift wrapper is tracked in #31.
public struct RereferenceAssetCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = RereferenceAssetConfig
  /// The command name.
  public static let commandName = "rereference-asset"
  /// The command abstract.
  public static let abstract = "Re-reference an asset across records (pending #31)"
  /// The command help text.
  public static let helpText = """
    REREFERENCE-ASSET - Re-reference an existing asset across records

    USAGE:
      mistdemo rereference-asset \\
        --source-record <name> --asset-field <field> \\
        --target-record <name> [--target-asset-field <field>]

    OPTIONS:
      --source-record <name>         Record name whose asset to reuse
      --asset-field <name>           Field on the source record holding the asset
      --target-record <name>         Record name receiving the asset reference
      --target-asset-field <name>    Field on the target record (defaults to --asset-field)
      --database <type>              Database to target
      --output-format <format>       Output format (json, table, csv, yaml)

    STATUS:
      Not yet implemented — pending MistKit support, tracked in #31.
    """

  private let config: RereferenceAssetConfig

  /// Creates a new instance.
  public init(config: RereferenceAssetConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    PendingStub.printPending(endpoint: "assets/rereference", trackingIssue: 31)
  }
}
