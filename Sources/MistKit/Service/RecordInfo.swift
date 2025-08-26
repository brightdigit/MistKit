//
//  RecordInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation

public struct RecordInfo: Encodable {
    public let recordName: String
    public let recordType: String
    public let fields: [String: FieldValue]
    
    internal init(from record: Components.Schemas.Record) {
        self.recordName = record.recordName ?? "Unknown"
        self.recordType = record.recordType ?? "Unknown"
        
        // Convert fields to FieldValue representation
        var convertedFields: [String: FieldValue] = [:]
        
        if let fieldsPayload = record.fields {
            for (fieldName, fieldData) in fieldsPayload.additionalProperties {
                if let fieldValue = Self.convertToFieldValue(fieldData) {
                    convertedFields[fieldName] = fieldValue
                }
            }
        }
        
        self.fields = convertedFields
    }
    
    /// Convert a CloudKit field value to FieldValue
    private static func convertToFieldValue(_ fieldData: Components.Schemas.FieldValue) -> FieldValue? {
        let value = fieldData.value
        
        #if DEBUG
        if let fieldType = fieldData._type {
            print("🔍 Converting field with type: \(fieldType)")
            if fieldType == .ASSETID || fieldType == .ASSET {
                print("📁 Asset field detected, value type: \(value)")
            }
        }
        #endif
        
        
        switch value {
        case .StringValue(let stringValue):
            return .string(stringValue)
        case .Int64Value(let intValue):
            return .int64(intValue)
        case .DoubleValue(let doubleValue):
            // Check the type to determine if it's a date or double
            if let fieldType = fieldData._type {
                switch fieldType {
                case .TIMESTAMP:
                    // Convert milliseconds to Date
                    let date = Date(timeIntervalSince1970: doubleValue / 1000)
                    return .date(date)
                default:
                    return .double(doubleValue)
                }
            } else {
                return .double(doubleValue)
            }
        case .BooleanValue(let boolValue):
            return .boolean(boolValue)
        case .BytesValue(let bytesValue):
            return .bytes(bytesValue)
        case .DateValue(let dateValue):
            // Convert milliseconds to Date
            let date = Date(timeIntervalSince1970: dateValue / 1000)
            return .date(date)
        case .LocationValue(let locationValue):
            let location = FieldValue.Location(
                latitude: locationValue.latitude ?? 0.0,
                longitude: locationValue.longitude ?? 0.0,
                horizontalAccuracy: locationValue.horizontalAccuracy,
                verticalAccuracy: locationValue.verticalAccuracy,
                altitude: locationValue.altitude,
                speed: locationValue.speed,
                course: locationValue.course,
                timestamp: locationValue.timestamp.map { Date(timeIntervalSince1970: $0 / 1000) }
            )
            return .location(location)
        case .ReferenceValue(let referenceValue):
            let reference = FieldValue.Reference(
                recordName: referenceValue.recordName ?? "",
                action: referenceValue.action?.rawValue
            )
            return .reference(reference)
        case .AssetValue(let assetValue):
            let asset = FieldValue.Asset(
                fileChecksum: assetValue.fileChecksum,
                size: assetValue.size,
                referenceChecksum: assetValue.referenceChecksum,
                wrappingKey: assetValue.wrappingKey,
                receipt: assetValue.receipt,
                downloadURL: assetValue.downloadURL
            )
            return .asset(asset)
        case .ListValue(let listValue):
            // Convert list items to FieldValue array
            let convertedList = listValue.compactMap { listItem in
                // Handle the recursive list structure properly
                switch listItem {
                case .StringValue(let stringValue):
                    return FieldValue.string(stringValue)
                case .Int64Value(let intValue):
                    return FieldValue.int64(intValue)
                case .DoubleValue(let doubleValue):
                    return FieldValue.double(doubleValue)
                case .BooleanValue(let boolValue):
                    return FieldValue.boolean(boolValue)
                case .BytesValue(let bytesValue):
                    return FieldValue.bytes(bytesValue)
                case .DateValue(let dateValue):
                    let date = Date(timeIntervalSince1970: dateValue / 1000)
                    return FieldValue.date(date)
                case .LocationValue(let locationValue):
                    let location = FieldValue.Location(
                        latitude: locationValue.latitude ?? 0.0,
                        longitude: locationValue.longitude ?? 0.0,
                        horizontalAccuracy: locationValue.horizontalAccuracy,
                        verticalAccuracy: locationValue.verticalAccuracy,
                        altitude: locationValue.altitude,
                        speed: locationValue.speed,
                        course: locationValue.course,
                        timestamp: locationValue.timestamp.map { Date(timeIntervalSince1970: $0 / 1000) }
                    )
                    return FieldValue.location(location)
                case .ReferenceValue(let refValue):
                    let reference = FieldValue.Reference(
                        recordName: refValue.recordName ?? "",
                        action: refValue.action?.rawValue
                    )
                    return FieldValue.reference(reference)
                case .AssetValue(let assetValue):
                    let asset = FieldValue.Asset(
                        fileChecksum: assetValue.fileChecksum,
                        size: assetValue.size,
                        referenceChecksum: assetValue.referenceChecksum,
                        wrappingKey: assetValue.wrappingKey,
                        receipt: assetValue.receipt,
                        downloadURL: assetValue.downloadURL
                    )
                    return FieldValue.asset(asset)
                case .ListValue(let nestedList):
                    // Recursively convert nested lists
                    let nestedConvertedList = nestedList.compactMap { nestedItem in
                        // For simplicity, we'll handle basic types in nested lists
                        switch nestedItem {
                        case .StringValue(let stringValue):
                            return FieldValue.string(stringValue)
                        case .Int64Value(let intValue):
                            return FieldValue.int64(intValue)
                        case .DoubleValue(let doubleValue):
                            return FieldValue.double(doubleValue)
                        case .BooleanValue(let boolValue):
                            return FieldValue.boolean(boolValue)
                        default:
                            // For complex nested types, return nil for now
                            return nil
                        }
                    }
                    return FieldValue.list(nestedConvertedList)
                }
            }
            return .list(convertedList)
        }
        
        #if DEBUG
        print("⚠️  Unhandled field value type: \(value) with fieldType: \(fieldData._type?.rawValue ?? "nil")")
        #endif
        return nil
    }
}
