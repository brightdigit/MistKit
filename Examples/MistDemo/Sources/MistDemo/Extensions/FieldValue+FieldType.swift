//
//  FieldValue+FieldType.swift
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
public import MistKit

extension FieldValue {
    /// Initialize FieldValue from a parsed value and field type
    ///
    /// This convenience initializer simplifies converting MistDemo's parsed field values
    /// into MistKit's FieldValue enum cases. It handles type conversion and validation.
    ///
    /// - Parameters:
    ///   - value: The parsed value (from FieldType.convertValue)
    ///   - fieldType: The MistDemo FieldType that specifies what type this value should be
    /// - Returns: A FieldValue if the conversion is successful, nil otherwise
    ///
    /// ## Example
    /// ```swift
    /// let field = try Field(parsing: "title:string:Hello")
    /// let convertedValue = try field.type.convertValue(field.value)
    /// if let fieldValue = FieldValue(value: convertedValue, fieldType: field.type) {
    ///     // Use fieldValue in CloudKit operations
    /// }
    /// ```
    public init?(value: Any, fieldType: FieldType) {
        switch fieldType {
        case .string:
            guard let stringValue = value as? String else { return nil }
            self = .string(stringValue)

        case .int64:
            if let intValue = value as? Int64 {
                self = .int64(Int(intValue))
            } else if let intValue = value as? Int {
                self = .int64(intValue)
            } else {
                return nil
            }

        case .double:
            guard let doubleValue = value as? Double else { return nil }
            self = .double(doubleValue)

        case .timestamp:
            guard let dateValue = value as? Date else { return nil }
            self = .date(dateValue)

        case .bytes:
            guard let stringValue = value as? String else { return nil }
            self = .bytes(stringValue)

        case .asset:
            // Value should be the URL from upload token
            guard let urlString = value as? String else { return nil }
            let asset = FieldValue.Asset(
                fileChecksum: nil,
                size: nil,
                referenceChecksum: nil,
                wrappingKey: nil,
                receipt: nil,
                downloadURL: urlString
            )
            self = .asset(asset)

        case .location, .reference:
            // These complex types require specialized handling
            // For now, return nil to indicate they're not supported via simple conversion
            return nil
        }
    }
}
