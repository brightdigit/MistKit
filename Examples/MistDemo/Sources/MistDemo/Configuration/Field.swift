//
//  Field.swift
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

/// Field definition for create operations
public struct Field: Sendable {
    public let name: String
    public let type: FieldType
    public let value: String
    
    public init(name: String, type: FieldType, value: String) {
        self.name = name
        self.type = type
        self.value = value
    }
    
    /// Parse a field from string format "name:type:value"
    public static func parse(_ input: String) throws -> Field {
        let components = input.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        
        guard components.count == 3 else {
            throw FieldParsingError.invalidFormat(input, expected: "name:type:value")
        }
        
        let name = String(components[0]).trimmingCharacters(in: .whitespaces)
        let typeString = String(components[1]).trimmingCharacters(in: .whitespaces)
        let value = String(components[2]) // Don't trim value as it may contain meaningful whitespace
        
        guard !name.isEmpty else {
            throw FieldParsingError.emptyFieldName(input)
        }
        
        guard let type = FieldType(rawValue: typeString.lowercased()) else {
            throw FieldParsingError.unknownFieldType(typeString, available: FieldType.allCases.map(\.rawValue))
        }
        
        return Field(name: name, type: type, value: value)
    }
    
    /// Parse multiple fields from an array of strings
    public static func parseFields(_ inputs: [String]) throws -> [Field] {
        return try inputs.map { try parse($0) }
    }
}