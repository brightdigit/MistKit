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

public import Foundation
import MistKit

/// Command to create a new record in CloudKit
public struct CreateCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = CreateConfig
    public static let commandName = "create"
    public static let abstract = "Create a new record in CloudKit"
    public static let helpText = """
        CREATE - Create a new record in CloudKit

        USAGE:
            mistdemo create [options]

        REQUIRED:
            --api-token <token>            CloudKit API token
            --web-auth-token <token>       Web authentication token

        OPTIONS:
            --record-type <type>           Record type to create (default: Note)
            --zone <zone>                  Zone name (default: _defaultZone)
            --record-name <name>           Custom record name (auto-generated if omitted)
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

          1. Single field:
             mistdemo create --field "title:string:My Note"

          2. Multiple fields (comma-separated):
             mistdemo create --field "title:string:My Note, priority:int64:5"

          3. With timestamp:
             mistdemo create --field "title:string:Task, due:timestamp:2026-02-01T09:00:00Z"

          4. From JSON file:
             mistdemo create --json-file fields.json

             Example fields.json:
             {
               "title": "Project Plan",
               "priority": 8,
               "progress": 0.35
             }

          5. From stdin:
             echo '{"title":"Quick Note"}' | mistdemo create --stdin

          6. Table output format:
             mistdemo create --field "title:string:Test" --output-format table

          7. With asset (after upload-asset):
             mistdemo create --field "title:string:My Photo, image:asset:https://cws.icloud-content.com:443/..."

        NOTES:
          • Record name is auto-generated if not provided
          • JSON files auto-detect field types from values
          • Use environment variables CLOUDKIT_API_TOKEN and CLOUDKIT_WEB_AUTH_TOKEN
            to avoid repeating tokens
        """
    
    private let config: CreateConfig
    
    public init(config: CreateConfig) {
        self.config = config
    }
    
    public func execute() async throws {
        do {
            // Create CloudKit client
            let client = try MistKitClientFactory.create(from: config.base)
            
            // Generate record name if not provided
            let recordName = config.recordName ?? generateRecordName()
            
            // Convert fields to CloudKit format
            let cloudKitFields = try config.fields.toCloudKitFields()

            // Create the record
            // NOTE: Zone support requires enhancements to CloudKitService.createRecord method
            let recordInfo = try await client.createRecord(
                recordType: config.recordType,
                recordName: recordName,
                fields: cloudKitFields
                // Zone: config.zone - to be added when CloudKitService supports it
            )
            
            // Format and output result
            try await outputResult(recordInfo, format: config.output)
            
        } catch {
            throw CreateError.operationFailed(error.localizedDescription)
        }
    }
    
    /// Generate a unique record name
    private func generateRecordName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomSuffix = String(Int.random(in: MistDemoConstants.Limits.randomSuffixMin...MistDemoConstants.Limits.randomSuffixMax))
        return "\(config.recordType.lowercased())-\(timestamp)-\(randomSuffix)"
    }
}

// CreateError is now defined in Errors/CreateError.swift