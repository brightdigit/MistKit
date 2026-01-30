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
public struct CreateCommand: MistDemoCommand {
    public static let commandName = "create"
    public static let abstract = "Create a new record in CloudKit"
    
    private let config: CreateConfig
    
    public init(config: CreateConfig) {
        self.config = config
    }
    
    /// Initialize from command line arguments using Swift Configuration
    public init() throws {
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
        
        self.config = CreateConfig(
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
            try await outputResult(recordInfo)
            
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
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard let fieldDict = jsonObject as? [String: Any] else {
                throw CreateError.invalidJSONFormat("JSON file must contain an object with field definitions")
            }
            
            return try convertJSONObjectToFields(fieldDict)
            
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
            let jsonObject = try JSONSerialization.jsonObject(with: stdinData)
            
            guard let fieldDict = jsonObject as? [String: Any] else {
                throw CreateError.invalidJSONFormat("Stdin must contain a JSON object with field definitions")
            }
            
            return try convertJSONObjectToFields(fieldDict)
            
        } catch {
            throw CreateError.stdinError(error.localizedDescription)
        }
    }
    
    /// Convert JSON object to Field array
    private static func convertJSONObjectToFields(_ jsonDict: [String: Any]) throws -> [Field] {
        var fields: [Field] = []
        
        for (fieldName, value) in jsonDict {
            // Infer field type from JSON value
            let field = try inferFieldFromJSONValue(name: fieldName, value: value)
            fields.append(field)
        }
        
        return fields
    }
    
    /// Infer Field from JSON value
    private static func inferFieldFromJSONValue(name: String, value: Any) throws -> Field {
        let fieldType: FieldType
        let stringValue: String
        
        switch value {
        case let stringVal as String:
            fieldType = .string
            stringValue = stringVal
        case let intVal as Int:
            fieldType = .int64
            stringValue = String(intVal)
        case let doubleVal as Double:
            fieldType = .double
            stringValue = String(doubleVal)
        case let boolVal as Bool:
            fieldType = .string // Convert bool to string
            stringValue = boolVal ? "true" : "false"
        default:
            // Try to convert to string
            fieldType = .string
            stringValue = String(describing: value)
        }
        
        return Field(name: name, type: fieldType, value: stringValue)
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
    
    /// Output the created record in the requested format
    private func outputResult(_ recordInfo: RecordInfo) async throws {
        switch config.output {
        case .json:
            let jsonData = try JSONEncoder().encode(recordInfo)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                throw CreateError.outputError("Failed to encode JSON")
            }
            print(jsonString)
            
        case .table:
            print(MistDemoConstants.Messages.recordCreated)
            print("├─ Name: \(recordInfo.recordName)")
            print("├─ Type: \(recordInfo.recordType)")
            if let changeTag = recordInfo.recordChangeTag {
                print("├─ Change Tag: \(changeTag)")
            }
            print("└─ Fields:")
            
            for (fieldName, fieldValue) in recordInfo.fields {
                let formattedValue = FieldValueFormatter.formatFieldValue(fieldValue)
                print("   ├─ \(fieldName): \(formattedValue)")
            }
            
        case .csv:
            let allFieldNames = [
                MistDemoConstants.FieldNames.recordName,
                MistDemoConstants.FieldNames.recordType,
                MistDemoConstants.FieldNames.recordChangeTag
            ] + recordInfo.fields.keys.sorted()
            
            // Print header
            print(allFieldNames.joined(separator: ","))
            
            // Print record
            var values: [String] = []
            for fieldName in allFieldNames {
                switch fieldName {
                case MistDemoConstants.FieldNames.recordName:
                    values.append(OutputEscaping.csvEscape(recordInfo.recordName))
                case MistDemoConstants.FieldNames.recordType:
                    values.append(OutputEscaping.csvEscape(recordInfo.recordType))
                case MistDemoConstants.FieldNames.recordChangeTag:
                    values.append(OutputEscaping.csvEscape(recordInfo.recordChangeTag ?? ""))
                default:
                    if let fieldValue = recordInfo.fields[fieldName] {
                        let formatted = FieldValueFormatter.formatFieldValue(fieldValue)
                        values.append(OutputEscaping.csvEscape(formatted))
                    } else {
                        values.append("")
                    }
                }
            }
            print(values.joined(separator: ","))
            
        case .yaml:
            print("record:")
            print("  \(MistDemoConstants.FieldNames.recordName): \(OutputEscaping.yamlEscape(recordInfo.recordName))")
            print("  \(MistDemoConstants.FieldNames.recordType): \(OutputEscaping.yamlEscape(recordInfo.recordType))")
            if let changeTag = recordInfo.recordChangeTag {
                print("  \(MistDemoConstants.FieldNames.recordChangeTag): \(OutputEscaping.yamlEscape(changeTag))")
            }
            print("  fields:")
            for (fieldName, fieldValue) in recordInfo.fields {
                let formatted = FieldValueFormatter.formatFieldValue(fieldValue)
                print("    \(fieldName): \(OutputEscaping.yamlEscape(formatted))")
            }
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
    case outputError(String)
    
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
        case .outputError(let message):
            return "Output formatting error: \(message)"
        }
    }
}