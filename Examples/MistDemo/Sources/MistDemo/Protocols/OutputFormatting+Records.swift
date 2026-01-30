//
//  OutputFormatting+Records.swift
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

// MARK: - RecordInfo Output Formatting

extension OutputFormatting {
    /// Output RecordInfo results in table format
    func outputRecordTable(_ records: [RecordInfo], fields: [String]? = nil) async throws {
        if records.isEmpty {
            print(MistDemoConstants.Messages.noRecordsFound)
            return
        }
        
        if records.count == 1 {
            // Single record - detailed view
            let record = records[0]
            print(MistDemoConstants.Messages.recordCreated)
            print("├─ Name: \(record.recordName)")
            print("├─ Type: \(record.recordType)")
            if let changeTag = record.recordChangeTag {
                print("├─ Change Tag: \(changeTag)")
            }
            print("└─ Fields:")
            
            let fieldsToShow = filterFields(record.fields, fields: fields)
            for (fieldName, fieldValue) in fieldsToShow {
                let formattedValue = FieldValueFormatter.formatFieldValue(fieldValue)
                print("   ├─ \(fieldName): \(formattedValue)")
            }
        } else {
            // Multiple records - list view
            print("Found \(records.count) record(s):")
            print(String(repeating: "=", count: 50))
            
            for (index, record) in records.enumerated() {
                print("\n[\(index + 1)] Record: \(record.recordName)")
                print("    Type: \(record.recordType)")
                if let changeTag = record.recordChangeTag {
                    print("    Change Tag: \(changeTag)")
                }
                print("    Fields:")
                
                let fieldsToShow = filterFields(record.fields, fields: fields)
                for (fieldName, fieldValue) in fieldsToShow {
                    let formattedValue = FieldValueFormatter.formatFieldValue(fieldValue)
                    print("      \(fieldName): \(formattedValue)")
                }
            }
        }
    }
    
    /// Output RecordInfo results in CSV format
    func outputRecordCSV(_ records: [RecordInfo], fields: [String]? = nil) async throws {
        // Collect all unique field names (filtered if requested)
        let allFieldNames = Set(records.flatMap { record in
            record.fields.keys.filter { fieldName in
                shouldIncludeField(fieldName, fields: fields)
            }
        })
        
        let sortedFieldNames = [
            MistDemoConstants.FieldNames.recordName,
            MistDemoConstants.FieldNames.recordType,
            MistDemoConstants.FieldNames.recordChangeTag
        ].filter { shouldIncludeField($0, fields: fields) } + allFieldNames.sorted()
        
        // Print header
        print(sortedFieldNames.joined(separator: ","))
        
        // Print records
        let csvEscaper = CSVEscaper()
        for record in records {
            var values: [String] = []
            for fieldName in sortedFieldNames {
                switch fieldName {
                case MistDemoConstants.FieldNames.recordName:
                    values.append(csvEscaper.escape(record.recordName))
                case MistDemoConstants.FieldNames.recordType:
                    values.append(csvEscaper.escape(record.recordType))
                case MistDemoConstants.FieldNames.recordChangeTag:
                    values.append(csvEscaper.escape(record.recordChangeTag ?? ""))
                default:
                    if let fieldValue = record.fields[fieldName] {
                        let formatted = FieldValueFormatter.formatFieldValue(fieldValue)
                        values.append(csvEscaper.escape(formatted))
                    } else {
                        values.append("")
                    }
                }
            }
            print(values.joined(separator: ","))
        }
    }
    
    /// Output RecordInfo results in YAML format
    func outputRecordYAML(_ records: [RecordInfo], fields: [String]? = nil) async throws {
        let yamlEscaper = YAMLEscaper()
        if records.count == 1 {
            let record = records[0]
            print("record:")
            print("  \(MistDemoConstants.FieldNames.recordName): \(yamlEscaper.escape(record.recordName))")
            print("  \(MistDemoConstants.FieldNames.recordType): \(yamlEscaper.escape(record.recordType))")
            if let changeTag = record.recordChangeTag {
                print("  \(MistDemoConstants.FieldNames.recordChangeTag): \(yamlEscaper.escape(changeTag))")
            }
            print("  fields:")

            let fieldsToShow = filterFields(record.fields, fields: fields)
            for (fieldName, fieldValue) in fieldsToShow {
                let formatted = FieldValueFormatter.formatFieldValue(fieldValue)
                print("    \(fieldName): \(yamlEscaper.escape(formatted))")
            }
        } else {
            print("records:")
            for record in records {
                print("  - \(MistDemoConstants.FieldNames.recordName): \(yamlEscaper.escape(record.recordName))")
                print("    \(MistDemoConstants.FieldNames.recordType): \(yamlEscaper.escape(record.recordType))")
                if let changeTag = record.recordChangeTag {
                    print("    \(MistDemoConstants.FieldNames.recordChangeTag): \(yamlEscaper.escape(changeTag))")
                }
                print("    fields:")

                let fieldsToShow = filterFields(record.fields, fields: fields)
                for (fieldName, fieldValue) in fieldsToShow {
                    let formatted = FieldValueFormatter.formatFieldValue(fieldValue)
                    print("      \(fieldName): \(yamlEscaper.escape(formatted))")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Filter fields based on the fields parameter
    private func filterFields(_ fields: [String: FieldValue], fields fieldsFilter: [String]?) -> [String: FieldValue] {
        guard let fieldsFilter = fieldsFilter, !fieldsFilter.isEmpty else {
            return fields
        }
        
        return fields.filter { fieldName, _ in
            shouldIncludeField(fieldName, fields: fieldsFilter)
        }
    }
    
    /// Check if a field should be included based on field filter
    private func shouldIncludeField(_ fieldName: String, fields: [String]?) -> Bool {
        guard let fields = fields, !fields.isEmpty else {
            return true // Include all fields if no filter specified
        }
        
        return fields.contains { requestedField in
            fieldName.lowercased() == requestedField.lowercased()
        }
    }
}