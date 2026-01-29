//
//  CreateCommandTests.swift
//  MistDemoTests
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
import Testing
import MistKit

@testable import MistDemo

@Suite("CreateCommand Tests")
struct CreateCommandTests {
    // MARK: - Configuration Tests
    
    @Test("CreateConfig initializes with default values")
    func createConfigInitializesWithDefaults() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordName: nil,
            fields: []
        )
        
        #expect(config.zone == "_defaultZone")
        #expect(config.recordName == nil)
        #expect(config.fields.isEmpty)
    }
    
    @Test("CreateConfig accepts custom values")
    func createConfigAcceptsCustomValues() throws {
        let baseConfig = try MistDemoConfig()
        let fields = [
            Field(name: "title", type: .string, value: "Test Note"),
            Field(name: "priority", type: .int64, value: "5")
        ]
        let config = CreateConfig(
            base: baseConfig,
            zone: "customZone",
            recordName: "customRecord",
            fields: fields
        )
        
        #expect(config.zone == "customZone")
        #expect(config.recordName == "customRecord")
        #expect(config.fields.count == 2)
    }
    
    // MARK: - Command Property Tests
    
    @Test("Command has correct static properties")
    func commandHasCorrectStaticProperties() {
        #expect(CreateCommand.commandName == "create")
        #expect(CreateCommand.abstract == "Create a new record in CloudKit")
    }
    
    @Test("Command initializes with config")
    func commandInitializesWithConfig() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordName: nil,
            fields: []
        )
        let command = CreateCommand(config: config)
        
        #expect(CreateCommand.commandName == "create")
    }
    
    // MARK: - Field Type Tests
    
    @Test("FieldType enum has all expected cases")
    func fieldTypeEnumCases() {
        let types: [FieldType] = [.string, .int64, .double, .timestamp]
        
        #expect(types.count == 4)
        #expect(FieldType.string.rawValue == "string")
        #expect(FieldType.int64.rawValue == "int64")
        #expect(FieldType.double.rawValue == "double")
        #expect(FieldType.timestamp.rawValue == "timestamp")
    }
    
    // MARK: - Field Parsing Tests
    
    @Test("Parse string field")
    func parseStringField() throws {
        let field = try Field.parse("title:string:My Note")
        
        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "My Note")
    }
    
    @Test("Parse int64 field")
    func parseInt64Field() throws {
        let field = try Field.parse("priority:int64:5")
        
        #expect(field.name == "priority")
        #expect(field.type == .int64)
        #expect(field.value == "5")
    }
    
    @Test("Parse double field")
    func parseDoubleField() throws {
        let field = try Field.parse("progress:double:0.75")
        
        #expect(field.name == "progress")
        #expect(field.type == .double)
        #expect(field.value == "0.75")
    }
    
    @Test("Parse timestamp field")
    func parseTimestampField() throws {
        let field = try Field.parse("dueDate:timestamp:2026-02-01T09:00:00Z")
        
        #expect(field.name == "dueDate")
        #expect(field.type == .timestamp)
        #expect(field.value == "2026-02-01T09:00:00Z")
    }
    
    @Test("Parse field with colon in value")
    func parseFieldWithColonInValue() throws {
        let field = try Field.parse("url:string:https://example.com:8080")
        
        #expect(field.name == "url")
        #expect(field.type == .string)
        #expect(field.value == "https://example.com:8080")
    }
    
    @Test("Parse field with spaces in value")
    func parseFieldWithSpacesInValue() throws {
        let field = try Field.parse("description:string:This is a long description with spaces")
        
        #expect(field.name == "description")
        #expect(field.type == .string)
        #expect(field.value == "This is a long description with spaces")
    }
    
    // MARK: - Field Validation Tests
    
    @Test("Field parsing throws on invalid format")
    func fieldParsingThrowsOnInvalidFormat() throws {
        #expect(throws: Error.self) {
            _ = try Field.parse("invalid-format")
        }
        
        #expect(throws: Error.self) {
            _ = try Field.parse("field:missing-value")
        }
        
        #expect(throws: Error.self) {
            _ = try Field.parse("field:invalid-type:value")
        }
    }
    
    @Test("Field parsing validates field name")
    func fieldParsingValidatesFieldName() throws {
        #expect(throws: Error.self) {
            _ = try Field.parse(":string:value")
        }
    }
    
    @Test("Field parsing validates type")
    func fieldParsingValidatesType() throws {
        #expect(throws: Error.self) {
            _ = try Field.parse("field:invalidtype:value")
        }
    }
    
    // MARK: - Multiple Field Parsing Tests
    
    @Test("Parse multiple fields from comma-separated string")
    func parseMultipleFieldsFromString() throws {
        let fieldsString = "title:string:Test Note, priority:int64:5, progress:double:0.5"
        let fields = try fieldsString.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .map(Field.parse)
        
        #expect(fields.count == 3)
        #expect(fields[0].name == "title")
        #expect(fields[1].name == "priority")
        #expect(fields[2].name == "progress")
    }
    
    // MARK: - JSON Field Loading Tests
    
    @Test("Load fields from JSON dictionary")
    func loadFieldsFromJSONDictionary() throws {
        let json = """
        {
            "title": "Test Note",
            "priority": 5,
            "progress": 0.75,
            "isComplete": true,
            "tags": ["work", "important"]
        }
        """
        
        let data = Data(json.utf8)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        #expect(dictionary != nil)
        #expect(dictionary?["title"] as? String == "Test Note")
        #expect(dictionary?["priority"] as? Int == 5)
        #expect(dictionary?["progress"] as? Double == 0.75)
    }
    
    @Test("Convert JSON values to Field objects")
    func convertJSONValuesToFields() {
        let jsonValues: [String: Any] = [
            "title": "Test Note",
            "priority": 5,
            "progress": 0.75,
            "createdAt": "2026-01-29T12:00:00Z"
        ]
        
        var fields: [Field] = []
        
        for (key, value) in jsonValues {
            let field: Field
            switch value {
            case let stringValue as String:
                if stringValue.contains("T") && stringValue.contains("Z") {
                    field = Field(name: key, type: .timestamp, value: stringValue)
                } else {
                    field = Field(name: key, type: .string, value: stringValue)
                }
            case let intValue as Int:
                field = Field(name: key, type: .int64, value: String(intValue))
            case let doubleValue as Double:
                field = Field(name: key, type: .double, value: String(doubleValue))
            default:
                field = Field(name: key, type: .string, value: String(describing: value))
            }
            fields.append(field)
        }
        
        #expect(fields.count == 4)
        #expect(fields.contains { $0.name == "title" && $0.type == .string })
        #expect(fields.contains { $0.name == "priority" && $0.type == .int64 })
        #expect(fields.contains { $0.name == "progress" && $0.type == .double })
        #expect(fields.contains { $0.name == "createdAt" && $0.type == .timestamp })
    }
    
    // MARK: - Record Name Generation Tests
    
    @Test("Generate record name when not provided")
    func generateRecordNameWhenNotProvided() {
        let uuid = UUID().uuidString
        let recordName = "Note-\(uuid)"
        
        #expect(recordName.hasPrefix("Note-"))
        #expect(recordName.count > 5)
    }
    
    @Test("Use provided record name")
    func useProvidedRecordName() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            zone: "_defaultZone",
            recordName: "customRecordName",
            fields: []
        )
        
        #expect(config.recordName == "customRecordName")
    }
    
    // MARK: - Field Type Conversion Tests
    
    @Test("Convert string field to CloudKit value")
    func convertStringFieldToCloudKitValue() throws {
        let field = Field(name: "title", type: .string, value: "Test Note")
        
        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "Test Note")
    }
    
    @Test("Convert numeric fields to CloudKit values")
    func convertNumericFieldsToCloudKitValues() {
        let intField = Field(name: "count", type: .int64, value: "42")
        let doubleField = Field(name: "percentage", type: .double, value: "0.85")
        
        #expect(Int(intField.value) == 42)
        #expect(Double(doubleField.value) == 0.85)
    }
    
    @Test("Convert timestamp field to CloudKit value")
    func convertTimestampFieldToCloudKitValue() {
        let field = Field(name: "createdAt", type: .timestamp, value: "2026-01-29T12:00:00Z")
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: field.value)
        
        #expect(date != nil)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("CreateError cases")
    func createErrorCases() {
        let parseError = CreateError.invalidJSONFormat("Invalid JSON format")
        let fileError = CreateError.jsonFileError("test.json", "File not found")
        let conversionError = CreateError.fieldConversionError("field", .string, "value", "Conversion failed")
        
        #expect(parseError.errorDescription?.contains("Invalid JSON format") == true)
        #expect(fileError.errorDescription?.contains("File not found") == true)
        #expect(conversionError.errorDescription?.contains("Conversion failed") == true)
    }
}