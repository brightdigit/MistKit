//
//  RecordInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation

/// Represents a CloudKit field value as defined in the CloudKit Web Services API
public enum FieldValue: Codable, Equatable {
    case string(String)
    case int64(Int64)
    case double(Double)
    case boolean(Bool)
    case bytes(String) // Base64-encoded string
    case date(Date) // Date/time value
    case location(Location)
    case reference(Reference)
    case asset(Asset)
    case list([FieldValue])
    
    /// Location dictionary as defined in CloudKit Web Services
    public struct Location: Codable, Equatable {
        public let latitude: Double
        public let longitude: Double
        public let horizontalAccuracy: Double?
        public let verticalAccuracy: Double?
        public let altitude: Double?
        public let speed: Double?
        public let course: Double?
        public let timestamp: Date?
        
        public init(
            latitude: Double,
            longitude: Double,
            horizontalAccuracy: Double? = nil,
            verticalAccuracy: Double? = nil,
            altitude: Double? = nil,
            speed: Double? = nil,
            course: Double? = nil,
            timestamp: Date? = nil
        ) {
            self.latitude = latitude
            self.longitude = longitude
            self.horizontalAccuracy = horizontalAccuracy
            self.verticalAccuracy = verticalAccuracy
            self.altitude = altitude
            self.speed = speed
            self.course = course
            self.timestamp = timestamp
        }
    }
    
    /// Reference dictionary as defined in CloudKit Web Services
    public struct Reference: Codable, Equatable {
        public let recordName: String
        public let action: String? // "DELETE_SELF" or nil
        
        public init(recordName: String, action: String? = nil) {
            self.recordName = recordName
            self.action = action
        }
    }
    
    /// Asset dictionary as defined in CloudKit Web Services
    public struct Asset: Codable, Equatable {
        public let fileChecksum: String?
        public let size: Int64?
        public let referenceChecksum: String?
        public let wrappingKey: String?
        public let receipt: String?
        public let downloadURL: String?
        
        public init(
            fileChecksum: String? = nil,
            size: Int64? = nil,
            referenceChecksum: String? = nil,
            wrappingKey: String? = nil,
            receipt: String? = nil,
            downloadURL: String? = nil
        ) {
            self.fileChecksum = fileChecksum
            self.size = size
            self.referenceChecksum = referenceChecksum
            self.wrappingKey = wrappingKey
            self.receipt = receipt
            self.downloadURL = downloadURL
        }
    }
    
    // MARK: - Codable
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int64(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .bytes(let value):
            try container.encode(value)
        case .date(let value):
            try container.encode(value.timeIntervalSince1970 * 1000)
        case .location(let value):
            try container.encode(value)
        case .reference(let value):
            try container.encode(value)
        case .asset(let value):
            try container.encode(value)
        case .list(let values):
            try container.encode(values)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try to decode in order of most specific to least specific
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        if let value = try? container.decode(Int64.self) {
            self = .int64(value)
            return
        }
        if let value = try? container.decode(Double.self) {
            self = .double(value)
            return
        }
        if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
            return
        }
        if let value = try? container.decode([FieldValue].self) {
            self = .list(value)
            return
        }
        if let value = try? container.decode(Location.self) {
            self = .location(value)
            return
        }
        if let value = try? container.decode(Reference.self) {
            self = .reference(value)
            return
        }
        if let value = try? container.decode(Asset.self) {
            self = .asset(value)
            return
        }
        // Try to decode as date (milliseconds since epoch)
        if let value = try? container.decode(Double.self) {
            self = .date(Date(timeIntervalSince1970: value / 1000))
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode FieldValue")
    }
}

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
