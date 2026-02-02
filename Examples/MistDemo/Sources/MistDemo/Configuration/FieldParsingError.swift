//
//  FieldParsingError.swift
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

/// Errors that can occur during field parsing
public enum FieldParsingError: Error, LocalizedError {
    case invalidFormat(String, expected: String)
    case emptyFieldName(String)
    case unknownFieldType(String, available: [String])
    case invalidValueForType(String, type: FieldType)
    case unsupportedFieldType(FieldType)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let input, let expected):
            return "Invalid field format '\(input)'. Expected format: \(expected)"
        case .emptyFieldName(let input):
            return "Empty field name in '\(input)'"
        case .unknownFieldType(let type, let available):
            return "Unknown field type '\(type)'. Available types: \(available.joined(separator: ", "))"
        case .invalidValueForType(let value, let type):
            return "Invalid value '\(value)' for field type '\(type.rawValue)'"
        case .unsupportedFieldType(let type):
            return "Field type '\(type.rawValue)' is not yet supported"
        }
    }
}