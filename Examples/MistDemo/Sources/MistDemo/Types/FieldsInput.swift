//
//  FieldsInput.swift
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

/// Type-safe representation of field input from JSON
public struct FieldsInput: Codable {
    private let storage: [String: FieldInputValue]
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        var fields: [String: FieldInputValue] = [:]
        
        for key in container.allKeys {
            if let stringValue = try? container.decode(String.self, forKey: key) {
                fields[key.stringValue] = .string(stringValue)
            } else if let intValue = try? container.decode(Int.self, forKey: key) {
                fields[key.stringValue] = .int(intValue)
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                fields[key.stringValue] = .double(doubleValue)
            } else if let boolValue = try? container.decode(Bool.self, forKey: key) {
                fields[key.stringValue] = .bool(boolValue)
            } else {
                // Try to decode as a generic JSON value and convert to string
                let jsonValue = try container.decode(AnyCodable.self, forKey: key)
                fields[key.stringValue] = .string(String(describing: jsonValue.value))
            }
        }
        
        self.storage = fields
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        
        for (key, value) in storage {
            let dynamicKey = DynamicKey(stringValue: key)!
            switch value {
            case .string(let stringValue):
                try container.encode(stringValue, forKey: dynamicKey)
            case .int(let intValue):
                try container.encode(intValue, forKey: dynamicKey)
            case .double(let doubleValue):
                try container.encode(doubleValue, forKey: dynamicKey)
            case .bool(let boolValue):
                try container.encode(boolValue, forKey: dynamicKey)
            case .asset(let url):
                try container.encode(url, forKey: dynamicKey)
            }
        }
    }
    
    /// Convert to Field array for CloudKit processing
    public func toFields() throws -> [Field] {
        return try storage.map { (name, value) in
            let (fieldType, stringValue) = try value.toFieldComponents()
            return Field(name: name, type: fieldType, value: stringValue)
        }
    }
}

