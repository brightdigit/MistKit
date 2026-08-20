//
//  DeleteCommand.swift
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

/// Command to delete an existing record from CloudKit
public struct DeleteCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = DeleteConfig
  /// The command name.
  public static let commandName = "delete"
  /// The command abstract.
  public static let abstract = "Delete an existing record from CloudKit"
  /// The command help text.
  public static let helpText = """
    DELETE - Delete an existing record from CloudKit

    USAGE:
      mistdemo delete --record-name <name> [options]

    REQUIRED:
      --record-name <name>         Record name to delete

    OPTIONS:
      --record-type <type>         Record type (default: Note)
      --record-change-tag <tag>    Optimistic locking tag
      --force                      Ignore change-tag mismatch
      --output-format <format>     Output format

    EXAMPLES:
      mistdemo delete --record-name my-note-123
      mistdemo delete --record-name my-note-123 --force
    """

  private let config: DeleteConfig

  /// Creates a new instance.
  public init(config: DeleteConfig) {
    self.config = config
  }

  internal static func mapConflict(
    _ error: CloudKitError
  ) -> DeleteError? {
    guard error.httpStatusCode == 409 else {
      return nil
    }
    switch error {
    case .conflict(let reason), .exists(let reason):
      return .conflict(reason: reason)
    case .httpErrorWithDetails(_, let reason):
      return .conflict(reason: reason)
    default:
      return .conflict(reason: nil)
    }
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      let client = try MistKitClientFactory.create(
        for: config.base
      )
      let effectiveChangeTag =
        config.force ? nil : config.recordChangeTag

      try await client.deleteRecord(
        recordType: config.recordType,
        recordName: config.recordName,
        recordChangeTag: effectiveChangeTag,
        database: config.base.database
      )

      let result = DeleteResult(
        recordName: config.recordName,
        recordType: config.recordType
      )
      try await outputResult(result, format: config.output)
    } catch let error as DeleteError {
      throw error
    } catch let error as CloudKitError {
      if let mapped = Self.mapConflict(error) {
        throw mapped
      }
      throw DeleteError.operationFailed(
        error.localizedDescription
      )
    } catch {
      throw DeleteError.operationFailed(
        error.localizedDescription
      )
    }
  }
}
