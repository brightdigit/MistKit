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
internal import MistKit

/// Command for `assets/rereference`. Reuses an existing CloudKit asset
/// descriptor from one record on another, avoiding a second upload of the
/// bytes.
public struct RereferenceAssetCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = RereferenceAssetConfig
  /// The command name.
  public static let commandName = "rereference-asset"
  /// The command abstract.
  public static let abstract = "Re-reference an asset across records"
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

    EXAMPLES:
      mistdemo rereference-asset \\
        --source-record note-a --asset-field image \\
        --target-record note-b
    """

  private let config: RereferenceAssetConfig

  /// Creates a new instance.
  public init(config: RereferenceAssetConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    guard let sourceRecord = config.sourceRecord else {
      throw RereferenceAssetError.sourceRecordRequired
    }
    guard let assetField = config.assetField else {
      throw RereferenceAssetError.assetFieldRequired
    }
    guard let targetRecord = config.targetRecord else {
      throw RereferenceAssetError.targetRecordRequired
    }

    print("\n" + String(repeating: "=", count: 60))
    print("📎 Re-reference Asset")
    print(String(repeating: "=", count: 60))
    print("   Source: \(sourceRecord).\(assetField)")
    print("   Target: \(targetRecord).\(config.targetAssetField ?? assetField)")

    do {
      let service = try MistKitClientFactory.create(for: config.base)
      let record = try await service.rereferenceAsset(
        fromRecord: RecordName(sourceRecord),
        field: assetField,
        toRecord: RecordName(targetRecord),
        field: config.targetAssetField,
        database: config.base.database
      )
      try await outputResult(record, format: config.output)
    } catch let error as CloudKitError {
      throw RereferenceAssetError.operationFailed(error.localizedDescription)
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Re-reference completed!")
    print(String(repeating: "=", count: 60))
  }
}
