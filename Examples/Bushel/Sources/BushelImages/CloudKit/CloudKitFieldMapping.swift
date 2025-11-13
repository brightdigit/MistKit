import Foundation
import MistKit

/// Helper utilities for converting between Swift types and CloudKit FieldValue types
enum CloudKitFieldMapping {
    /// Convert a String to FieldValue
    static func fieldValue(from string: String) -> FieldValue {
        .string(string)
    }

    /// Convert an optional String to FieldValue
    static func fieldValue(from string: String?) -> FieldValue? {
        string.map { .string($0) }
    }

    /// Convert a Bool to FieldValue (using INT64 representation: 0 = false, 1 = true)
    static func fieldValue(from bool: Bool) -> FieldValue {
        .from(bool)
    }

    /// Convert an Int64 to FieldValue
    static func fieldValue(from int64: Int64) -> FieldValue {
        .int64(Int(int64))
    }

    /// Convert an optional Int64 to FieldValue
    static func fieldValue(from int64: Int64?) -> FieldValue? {
        int64.map { .int64(Int($0)) }
    }

    /// Convert a Date to FieldValue
    static func fieldValue(from date: Date) -> FieldValue {
        .date(date)
    }

    /// Convert a CloudKit reference (recordName) to FieldValue
    static func referenceFieldValue(recordName: String) -> FieldValue {
        .reference(FieldValue.Reference(recordName: recordName))
    }

    /// Convert an optional CloudKit reference to FieldValue
    static func referenceFieldValue(recordName: String?) -> FieldValue? {
        recordName.map { .reference(FieldValue.Reference(recordName: $0)) }
    }

    /// Extract String from FieldValue
    static func string(from fieldValue: FieldValue) -> String? {
        if case .string(let value) = fieldValue {
            return value
        }
        return nil
    }

    /// Extract Bool from FieldValue (from INT64 representation: 0 = false, non-zero = true)
    static func bool(from fieldValue: FieldValue) -> Bool? {
        if case .int64(let value) = fieldValue {
            return value != 0
        }
        return nil
    }

    /// Extract Int64 from FieldValue
    static func int64(from fieldValue: FieldValue) -> Int64? {
        if case .int64(let value) = fieldValue {
            return Int64(value)
        }
        return nil
    }

    /// Extract Date from FieldValue
    static func date(from fieldValue: FieldValue) -> Date? {
        if case .date(let value) = fieldValue {
            return value
        }
        return nil
    }

    /// Extract reference recordName from FieldValue
    static func recordName(from fieldValue: FieldValue) -> String? {
        if case .reference(let reference) = fieldValue {
            return reference.recordName
        }
        return nil
    }
}
