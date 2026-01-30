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

        NOTES:
          • Record name is auto-generated if not provided
          • JSON files auto-detect field types from values
          • Use environment variables CLOUDKIT_API_TOKEN and CLOUDKIT_WEBAUTH_TOKEN
            to avoid repeating tokens
        """
    
    private let config: CreateConfig
    
    public init(config: CreateConfig) {
        self.config = config
    }
    
    /// Parse configuration from command line arguments
    public static func parseConfig() async throws -> CreateConfig {
        let configReader = try MistDemoConfiguration()
        let baseConfig = try MistDemoConfig()
        
        // Parse create-specific options
        let zone = configReader.string(forKey: MistDemoConstants.ConfigKeys.zone, default: MistDemoConstants.Defaults.zone) ?? MistDemoConstants.Defaults.zone
        let recordType = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordType, default: MistDemoConstants.Defaults.recordType) ?? MistDemoConstants.Defaults.recordType
        let recordName = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordName)
        
        // Parse fields from various sources
        let fields = try Self.parseFieldsFromSources(configReader)
        
        // Parse output format
        let outputString = configReader.string(forKey: MistDemoConstants.ConfigKeys.outputFormat, default: MistDemoConstants.Defaults.outputFormat) ?? MistDemoConstants.Defaults.outputFormat
        let output = OutputFormat(rawValue: outputString) ?? .json
        
        return CreateConfig(
            base: baseConfig,
            zone: zone,
            recordType: recordType,
            recordName: recordName,
            fields: fields,
            output: output
        )
    }
    
    public func execute() async throws {
        do {
            // Create CloudKit client
            let client = try MistKitClientFactory.create(from: config.base)
            
            // Generate record name if not provided
            let recordName = config.recordName ?? generateRecordName()
            
            // Convert fields to CloudKit format
            let cloudKitFields = try convertFieldsToCloudKit(config.fields)
            
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
    
    /// Parse fields from multiple sources (CLI args, JSON file, stdin)
    private static func parseFieldsFromSources(_ configReader: MistDemoConfiguration) throws -> [Field] {
        var fields: [Field] = []
        
        // 1. Parse inline field definitions
        if let fieldString = configReader.string(forKey: "field") {
            let fieldDefinitions = fieldString.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            let inlineFields = try Field.parseFields(fieldDefinitions)
            fields.append(contentsOf: inlineFields)
        }
        
        // 2. Parse from JSON file
        if let jsonFile = configReader.string(forKey: MistDemoConstants.ConfigKeys.jsonFile) {
            let jsonFields = try parseFieldsFromJSONFile(jsonFile)
            fields.append(contentsOf: jsonFields)
        }
        
        // 3. Parse from stdin (check if data is available)
        if configReader.bool(forKey: MistDemoConstants.ConfigKeys.stdin, default: false) {
            let stdinFields = try parseFieldsFromStdin()
            fields.append(contentsOf: stdinFields)
        }
        
        guard !fields.isEmpty else {
            throw CreateError.noFieldsProvided
        }
        
        return fields
    }
    
    /// Parse fields from JSON file
    private static func parseFieldsFromJSONFile(_ filePath: String) throws -> [Field] {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
            return try fieldsInput.toFields()
        } catch {
            throw CreateError.jsonFileError(filePath, error.localizedDescription)
        }
    }
    
    /// Parse fields from stdin
    private static func parseFieldsFromStdin() throws -> [Field] {
        let stdinData = FileHandle.standardInput.readDataToEndOfFile()
        
        guard !stdinData.isEmpty else {
            throw CreateError.emptyStdin
        }
        
        do {
            let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: stdinData)
            return try fieldsInput.toFields()
        } catch {
            throw CreateError.stdinError(error.localizedDescription)
        }
    }
    
    
    /// Generate a unique record name
    private func generateRecordName() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomSuffix = String(Int.random(in: MistDemoConstants.Limits.randomSuffixMin...MistDemoConstants.Limits.randomSuffixMax))
        return "\(config.recordType.lowercased())-\(timestamp)-\(randomSuffix)"
    }
    
    /// Convert Field array to CloudKit fields dictionary
    private func convertFieldsToCloudKit(_ fields: [Field]) throws -> [String: FieldValue] {
        var cloudKitFields: [String: FieldValue] = [:]
        
        for field in fields {
            do {
                let convertedValue = try field.type.convertValue(field.value)
                let fieldValue = try convertToFieldValue(convertedValue, type: field.type)
                cloudKitFields[field.name] = fieldValue
            } catch {
                throw CreateError.fieldConversionError(field.name, field.type, field.value, error.localizedDescription)
            }
        }
        
        return cloudKitFields
    }
    
    /// Convert a value to the appropriate FieldValue enum case
    private func convertToFieldValue(_ value: Any, type: FieldType) throws -> FieldValue {
        switch type {
        case .string:
            guard let stringValue = value as? String else {
                throw CreateError.fieldConversionError("", type, String(describing: value), "Expected string value")
            }
            return .string(stringValue)
        case .int64:
            guard let intValue = value as? Int64 else {
                throw CreateError.fieldConversionError("", type, String(describing: value), "Expected Int64 value")
            }
            return .int64(Int(intValue))
        case .double:
            guard let doubleValue = value as? Double else {
                throw CreateError.fieldConversionError("", type, String(describing: value), "Expected Double value")
            }
            return .double(doubleValue)
        case .timestamp:
            guard let dateValue = value as? Date else {
                throw CreateError.fieldConversionError("", type, String(describing: value), "Expected Date value")
            }
            return .date(dateValue)
        case .asset, .location, .reference, .bytes:
            throw CreateError.fieldConversionError("", type, String(describing: value), "Field type not yet supported")
        }
    }
}

/// Errors specific to create command
public enum CreateError: Error, LocalizedError {
    case noFieldsProvided
    case invalidJSONFormat(String)
    case jsonFileError(String, String)
    case emptyStdin
    case stdinError(String)
    case fieldConversionError(String, FieldType, String, String)
    case operationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noFieldsProvided:
            return MistDemoConstants.Messages.noFieldsProvided
        case .invalidJSONFormat(let message):
            return "Invalid JSON format: \(message)"
        case .jsonFileError(let file, let error):
            return "Error reading JSON file '\(file)': \(error)"
        case .emptyStdin:
            return "Empty stdin provided. Expected JSON object with field definitions."
        case .stdinError(let error):
            return "Error reading from stdin: \(error)"
        case .fieldConversionError(let name, let type, let value, let error):
            return "Failed to convert field '\(name)' of type '\(type.rawValue)' with value '\(value)': \(error)"
        case .operationFailed(let message):
            return "Create operation failed: \(message)"
        }
    }
}