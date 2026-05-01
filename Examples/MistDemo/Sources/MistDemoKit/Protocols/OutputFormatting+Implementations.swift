//
//  OutputFormatting+Implementations.swift
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

// MARK: - Format-specific implementations

extension OutputFormatting {
    /// Output results in JSON format
    func outputJSON<T: Encodable>(_ results: [T]) async throws {
        let jsonData: Data
        if results.count == 1 {
            jsonData = try JSONEncoder().encode(results[0])
        } else {
            jsonData = try JSONEncoder().encode(results)
        }
        
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw OutputFormattingError.encodingFailure("Failed to encode JSON")
        }
        
        print(jsonString)
    }
    
    /// Output results in table format
    func outputTable<T: Encodable>(_ results: [T]) async throws {
        if results.isEmpty {
            print(MistDemoConstants.Messages.noRecordsFound)
            return
        }
        
        // Table output is type-specific, so we need to handle known types
        if let records = results as? [RecordInfo] {
            try await outputRecordTable(records)
        } else if let userInfo = results.first as? UserInfo, results.count == 1 {
            try await outputUserTable(userInfo)
        } else {
            // Fall back to JSON for unknown types
            try await outputJSON(results)
        }
    }
    
    /// Output results in CSV format
    func outputCSV<T: Encodable>(_ results: [T]) async throws {
        // CSV output is type-specific, so we need to handle known types
        if let records = results as? [RecordInfo] {
            try await outputRecordCSV(records)
        } else if let userInfo = results.first as? UserInfo, results.count == 1 {
            try await outputUserCSV([userInfo])
        } else {
            // Fall back to JSON for unknown types
            try await outputJSON(results)
        }
    }
    
    /// Output results in YAML format
    func outputYAML<T: Encodable>(_ results: [T]) async throws {
        // YAML output is type-specific, so we need to handle known types
        if let records = results as? [RecordInfo] {
            try await outputRecordYAML(records)
        } else if let userInfo = results.first as? UserInfo, results.count == 1 {
            try await outputUserYAML(userInfo)
        } else {
            // Fall back to JSON for unknown types
            try await outputJSON(results)
        }
    }
}