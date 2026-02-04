//
//  UpdateError.swift
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

/// Errors that can occur during update command execution
public enum UpdateError: Error, LocalizedError {
    case recordNameRequired
    case noFieldsProvided
    case fieldConversionError(String, FieldType, String, String)
    case jsonFileError(String, String)
    case emptyStdin
    case stdinError(String)
    case operationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .recordNameRequired:
            return "Record name is required for update operations. Use --record-name <name>"
        case .noFieldsProvided:
            return "No fields provided. Use --field, --json-file, or --stdin to specify fields to update"
        case .fieldConversionError(let fieldName, let fieldType, let value, let reason):
            return "Failed to convert field '\(fieldName)' of type '\(fieldType.rawValue)' with value '\(value)': \(reason)"
        case .jsonFileError(let filename, let reason):
            return "Failed to read JSON file '\(filename)': \(reason)"
        case .emptyStdin:
            return "Empty stdin. Provide JSON data when using --stdin"
        case .stdinError(let reason):
            return "Failed to read from stdin: \(reason)"
        case .operationFailed(let reason):
            return "Update operation failed: \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .recordNameRequired:
            return "Specify a record name: mistdemo update --record-name my-record-123 --field \"title:string:Updated\""
        case .noFieldsProvided:
            return "Provide at least one field to update using --field, --json-file, or --stdin"
        case .fieldConversionError:
            return "Check that the field value matches the expected type. Use --help for field type information"
        case .jsonFileError:
            return "Ensure the JSON file exists and contains valid JSON"
        case .emptyStdin:
            return "Pipe JSON data to stdin: echo '{\"title\":\"Updated\"}' | mistdemo update --record-name my-record --stdin"
        case .stdinError, .operationFailed:
            return nil
        }
    }
}
