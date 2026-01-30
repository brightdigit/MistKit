//
//  CreateError.swift
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
