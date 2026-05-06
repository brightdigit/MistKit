//
//  UpdateCommand.swift
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

import Foundation
import MistKit

/// Command to update an existing record in CloudKit
public struct UpdateCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = UpdateConfig
  /// The command name.
  public static let commandName = "update"
  /// The command abstract.
  public static let abstract = "Update an existing record in CloudKit"
  /// The command help text.
  public static let helpText = """
    UPDATE - Update an existing record in CloudKit

    USAGE:
      mistdemo update --record-name <name> [options]

    REQUIRED:
      --record-name <name>         Record name to update

    OPTIONS:
      --record-type <type>         Record type (default: Note)
      --record-change-tag <tag>    Optimistic locking tag
      --force                      Overwrite ignoring conflicts
      --output-format <format>     Output format

    FIELD DEFINITION:
      --field <name:type:value>    Inline field definition
      --json-file <file>           Load fields from JSON
      --stdin                      Read fields from stdin

    EXAMPLES:
      mistdemo update --record-name my-note-123 \\
        --field "title:string:Updated Title"
      mistdemo update --record-name my-note-123 \\
        --json-file updates.json
    """

  private let config: UpdateConfig

  /// Creates a new instance.
  public init(config: UpdateConfig) {
    self.config = config
  }

  private static func mapConflict(
    _ error: CloudKitError
  ) -> UpdateError? {
    switch error {
    case .httpError(let statusCode) where statusCode == 409:
      return .conflict(reason: nil)
    case .httpErrorWithDetails(
      let statusCode, _, let reason
    ) where statusCode == 409:
      return .conflict(reason: reason)
    case .httpErrorWithRawResponse(
      let statusCode, _
    ) where statusCode == 409:
      return .conflict(reason: nil)
    default:
      return nil
    }
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      let client = try MistKitClientFactory.create(
        for: config.base
      )
      let cloudKitFields = try config.fields.toCloudKitFields()
      let effectiveChangeTag =
        config.force ? nil : config.recordChangeTag

      let recordInfo = try await client.updateRecord(
        recordType: config.recordType,
        recordName: config.recordName,
        fields: cloudKitFields,
        recordChangeTag: effectiveChangeTag
      )

      try await outputResult(recordInfo, format: config.output)
    } catch let error as UpdateError {
      throw error
    } catch let error as CloudKitError {
      if let mapped = Self.mapConflict(error) {
        throw mapped
      }
      throw UpdateError.operationFailed(
        error.localizedDescription
      )
    } catch {
      throw UpdateError.operationFailed(
        error.localizedDescription
      )
    }
  }
}
