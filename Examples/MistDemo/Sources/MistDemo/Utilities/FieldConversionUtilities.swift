//
//  FieldConversionUtilities.swift
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
public import MistKit

/// Shared utilities for converting field values to CloudKit format
public enum FieldConversionUtilities {
    /// Convert Field array to CloudKit fields dictionary
    /// - Parameter fields: Array of Field objects to convert
    /// - Returns: Dictionary of field names to FieldValue enums
    /// - Throws: FieldConversionError if conversion fails
    public static func convertFieldsToCloudKit(_ fields: [Field]) throws -> [String: FieldValue] {
        var cloudKitFields: [String: FieldValue] = [:]

        for field in fields {
            do {
                let convertedValue = try field.type.convertValue(field.value)
                let fieldValue = try convertToFieldValue(convertedValue, type: field.type)
                cloudKitFields[field.name] = fieldValue
            } catch {
                throw FieldConversionError.conversionFailed(
                    fieldName: field.name,
                    fieldType: field.type,
                    value: field.value,
                    reason: error.localizedDescription
                )
            }
        }

        return cloudKitFields
    }

    /// Convert a value to the appropriate FieldValue enum case
    /// - Parameters:
    ///   - value: The value to convert
    ///   - type: The field type
    /// - Returns: A FieldValue enum case
    /// - Throws: FieldConversionError if conversion fails
    public static func convertToFieldValue(_ value: Any, type: FieldType) throws -> FieldValue {
        guard let fieldValue = FieldValue(value: value, fieldType: type) else {
            throw FieldConversionError.invalidFieldValue(
                fieldType: type,
                value: String(describing: value)
            )
        }
        return fieldValue
    }

    /// Convert AssetUploadToken to FieldValue.Asset
    /// - Parameters:
    ///   - token: The asset upload token from uploadAssets
    ///   - fileSize: Optional file size in bytes (currently unused - CloudKit manages this)
    /// - Returns: A FieldValue.Asset enum case
    public static func assetFieldValue(from token: AssetUploadToken, fileSize: Int64? = nil) -> FieldValue {
        // After uploading an asset, only the downloadURL should be set
        // CloudKit manages the other fields internally
        let asset = FieldValue.Asset(
            fileChecksum: nil,
            size: nil,
            referenceChecksum: nil,
            wrappingKey: nil,
            receipt: nil,
            downloadURL: token.url
        )
        return .asset(asset)
    }
}

/// Errors that can occur during field conversion
public enum FieldConversionError: Error, LocalizedError {
    case conversionFailed(fieldName: String, fieldType: FieldType, value: String, reason: String)
    case invalidFieldValue(fieldType: FieldType, value: String)

    public var errorDescription: String? {
        switch self {
        case .conversionFailed(let fieldName, let fieldType, let value, let reason):
            return "Failed to convert field '\(fieldName)' of type '\(fieldType.rawValue)' with value '\(value)': \(reason)"
        case .invalidFieldValue(let fieldType, let value):
            return "Unable to convert value '\(value)' to FieldValue for type '\(fieldType.rawValue)'"
        }
    }
}
