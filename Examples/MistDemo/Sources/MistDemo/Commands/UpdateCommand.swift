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

public import Foundation
import MistKit

/// Command to update an existing record in CloudKit
public struct UpdateCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = UpdateConfig
    public static let commandName = "update"
    public static let abstract = "Update an existing record in CloudKit"
    public static let helpText = """
        UPDATE - Update an existing record in CloudKit

        USAGE:
            mistdemo update --record-name <name> [options]

        REQUIRED:
            --api-token <token>            CloudKit API token
            --web-auth-token <token>       Web authentication token
            --record-name <name>           Record name to update (REQUIRED)

        OPTIONS:
            --record-type <type>           Record type (default: Note)
            --zone <zone>                  Zone name (default: _defaultZone)
            --record-change-tag <tag>      Change tag for optimistic locking
            --output-format <format>       Output format: json, table, csv, yaml

        FIELD DEFINITION (choose one method):
            --field <name:type:value>      Inline field definition
            --json-file <file>             Load fields from JSON file
            --stdin                        Read fields from stdin as JSON

        FIELD FORMAT:
            Format: name:type:value
            Multiple fields: separate with commas

        FIELD TYPES:
            string      Text values
            int64       Integer numbers
            double      Decimal numbers
            timestamp   Dates (ISO 8601 or Unix timestamp)
            asset       Asset URL (from upload-asset command)

        EXAMPLES:

          1. Update single field:
             mistdemo update --record-name my-note-123 --field "title:string:Updated Title"

          2. Update multiple fields (comma-separated):
             mistdemo update --record-name my-note-123 --field "title:string:New Title, priority:int64:8"

          3. With optimistic locking:
             mistdemo update --record-name my-note-123 \\
               --record-change-tag abc123 --field "title:string:Safe Update"

          4. From JSON file:
             mistdemo update --record-name my-note-123 --json-file updates.json

             Example updates.json:
             {
               "title": "Updated Project Plan",
               "priority": 9,
               "progress": 0.75
             }

          5. From stdin:
             echo '{"title":"Quick Update"}' | mistdemo update --record-name my-note-123 --stdin

          6. Table output format:
             mistdemo update --record-name my-note-123 --field "title:string:Test" --output-format table

          7. Update asset field (after upload-asset):
             mistdemo update --record-name my-note-123 \\
               --field "image:asset:https://cws.icloud-content.com:443/..."

        NOTES:
          • Record name is REQUIRED for updates
          • Only specified fields will be updated, others remain unchanged
          • Use record-change-tag for safe concurrent updates
          • Use environment variables CLOUDKIT_API_TOKEN and CLOUDKIT_WEB_AUTH_TOKEN
            to avoid repeating tokens
        """

    private let config: UpdateConfig

    public init(config: UpdateConfig) {
        self.config = config
    }

    public func execute() async throws {
        do {
            // Create CloudKit client
            let client = try MistKitClientFactory.create(from: config.base)

            // Convert fields to CloudKit format
            let cloudKitFields = try config.fields.toCloudKitFields()

            // Update the record
            let recordInfo = try await client.updateRecord(
                recordType: config.recordType,
                recordName: config.recordName,
                fields: cloudKitFields,
                recordChangeTag: config.recordChangeTag
            )

            // Format and output result
            try await outputResult(recordInfo, format: config.output)

        } catch {
            throw UpdateError.operationFailed(error.localizedDescription)
        }
    }
}
