//
//  CreateCommand.swift
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

/// Command to create a new record in CloudKit
public struct CreateCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = CreateConfig
  /// The command name.
  public static let commandName = "create"
  /// The command abstract.
  public static let abstract = "Create a new record in CloudKit"
  /// The command help text.
  public static let helpText = """
    CREATE - Create a new record in CloudKit

    USAGE:
      mistdemo create [options]

    OPTIONS:
      --record-type <type>         Record type (default: Note)
      --record-name <name>         Custom record name
      --output-format <format>     Output format

    FIELD DEFINITION:
      --field <name:type:value>    Inline field definition
      --json-file <file>           Load fields from JSON
      --stdin                      Read fields from stdin

    EXAMPLES:
      mistdemo create --field "title:string:My Note"
      mistdemo create --json-file fields.json
    """

  private let config: CreateConfig

  /// Creates a new instance.
  public init(config: CreateConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      // Create CloudKit client
      let client = try MistKitClientFactory.create(for: config.base)

      // Generate record name if not provided
      let recordName = config.recordName ?? generateRecordName()

      // Convert fields to CloudKit format
      let cloudKitFields = try config.fields.toCloudKitFields()

      // Create the record
      // NOTE: Zone support requires enhancements to CloudKitService.createRecord method
      let recordInfo = try await client.createRecord(
        recordType: config.recordType,
        recordName: RecordName(recordName),
        fields: cloudKitFields,
        // Zone: config.zone - to be added when CloudKitService supports it
        database: config.base.database
      )

      // Format and output result
      try await outputResult(recordInfo, format: config.output)
    } catch {
      throw CreateError.operationFailed(error.localizedDescription)
    }
  }

  /// Generate a unique record name
  internal func generateRecordName() -> String {
    let timestamp = Int(Date().timeIntervalSince1970)
    let minSuffix = MistDemoConstants.Limits.randomSuffixMin
    let maxSuffix = MistDemoConstants.Limits.randomSuffixMax
    let randomSuffix = String(Int.random(in: minSuffix...maxSuffix))
    return "\(config.recordType.lowercased())-\(timestamp)-\(randomSuffix)"
  }
}

// CreateError is now defined in Errors/CreateError.swift
