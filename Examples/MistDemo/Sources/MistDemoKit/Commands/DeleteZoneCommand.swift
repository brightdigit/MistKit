//
//  DeleteZoneCommand.swift
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

/// Command to delete a single CloudKit zone.
public struct DeleteZoneCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = DeleteZoneConfig
  /// The command name.
  public static let commandName = "delete-zone"
  /// The command abstract.
  public static let abstract = "Delete a single CloudKit zone"
  /// The command help text.
  public static let helpText = """
    DELETE-ZONE - Delete a single CloudKit zone

    USAGE:
      mistdemo delete-zone --zone-name <name> [options]

    OPTIONS:
      --zone-name <name>         Zone name to delete (required)
      --zone-owner <owner>       Optional owner record name
      --database <type>          Database to target (private or shared)
      --output-format <format>   Output format

    EXAMPLES:
      mistdemo delete-zone --zone-name Articles
      mistdemo delete-zone --zone-name SharedZone --database shared

    NOTES:
      - The .public database does not support custom zones
      - Deleting a zone removes ALL records inside it
      - Auth method follows --database
      - Zone names are case-sensitive
    """

  private let config: DeleteZoneConfig

  /// Creates a new instance.
  public init(config: DeleteZoneConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🗑️  Delete CloudKit Zone")
    print(String(repeating: "=", count: 60))

    let service = try MistKitClientFactory.create(for: config.base)

    print("\n📋 Deleting zone:")
    print("   - Name: \(config.zoneName)")
    if let owner = config.ownerRecordName {
      print("   - Owner: \(owner)")
    }
    print("   - Database: \(config.base.database)")

    try await service.deleteZone(
      zoneName: config.zoneName,
      ownerRecordName: config.ownerRecordName,
      database: config.base.database
    )

    print("\n✅ Deleted zone '\(config.zoneName)'")

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Zone deletion completed!")
    print(String(repeating: "=", count: 60))
  }
}
