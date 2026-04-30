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

import Foundation
import MistKit

/// Result of a successful delete, formatted as command output.
public struct DeleteResult: Encodable, Sendable {
    public let recordName: String
    public let recordType: String
    public let deleted: Bool

    public init(recordName: String, recordType: String, deleted: Bool = true) {
        self.recordName = recordName
        self.recordType = recordType
        self.deleted = deleted
    }
}

/// Command to delete an existing record from CloudKit
public struct DeleteCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = DeleteConfig
    public static let commandName = "delete"
    public static let abstract = "Delete an existing record from CloudKit"
    public static let helpText = """
        DELETE - Delete an existing record from CloudKit

        USAGE:
            mistdemo delete --record-name <name> [options]

        REQUIRED:
            --api-token <token>            CloudKit API token
            --web-auth-token <token>       Web authentication token
            --record-name <name>           Record name to delete (REQUIRED)

        OPTIONS:
            --record-type <type>           Record type (default: Note)
            --zone <zone>                  Zone name (default: _defaultZone)
            --record-change-tag <tag>      Change tag for optimistic locking
            --force                        Delete record despite change-tag mismatch
            --output-format <format>       Output format: json, table, csv, yaml

        EXAMPLES:

          1. Delete a record:
             mistdemo delete --record-name my-note-123

          2. Delete with optimistic locking:
             mistdemo delete --record-name my-note-123 --record-change-tag abc123

          3. Force delete (ignore change tag):
             mistdemo delete --record-name my-note-123 --force

        NOTES:
          • Record name is REQUIRED
          • Without --force, the server's change-tag check will fail if the
            record was modified after the tag was issued. Use --force to
            overwrite that check.
        """

    private let config: DeleteConfig

    public init(config: DeleteConfig) {
        self.config = config
    }

    public func execute() async throws {
        do {
            let client = try MistKitClientFactory.create(.private, from: config.base)

            // --force omits the change tag so the server deletes without optimistic locking
            let effectiveChangeTag = config.force ? nil : config.recordChangeTag

            try await client.deleteRecord(
                recordType: config.recordType,
                recordName: config.recordName,
                recordChangeTag: effectiveChangeTag
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
            throw DeleteError.operationFailed(error.localizedDescription)
        } catch {
            throw DeleteError.operationFailed(error.localizedDescription)
        }
    }

    internal static func mapConflict(_ error: CloudKitError) -> DeleteError? {
        guard error.httpStatusCode == 409 else { return nil }
        if case .httpErrorWithDetails(_, _, let reason) = error {
            return .conflict(reason: reason)
        }
        return .conflict(reason: nil)
    }
}
