//  FieldValueExtensions.swift
//  Created by Claude Code

import Foundation
import MistKit

extension FieldValue {
    /// Extract a String value if this is a .string case
    var stringValue: String? {
        if case .string(let value) = self {
            return value
        }
        return nil
    }

    /// Extract an Int value if this is an .int64 case
    var intValue: Int? {
        if case .int64(let value) = self {
            return value
        }
        return nil
    }

    /// Extract a Double value if this is a .double case
    var doubleValue: Double? {
        if case .double(let value) = self {
            return value
        }
        return nil
    }

    /// Extract a Date value if this is a .date case
    var dateValue: Date? {
        if case .date(let value) = self {
            return value
        }
        return nil
    }

    /// Extract a Bool value from an .int64 case (CloudKit represents booleans as 0/1)
    var boolValue: Bool? {
        if case .int64(let value) = self {
            assert(value == 0 || value == 1, "Boolean FieldValue must be 0 or 1, got \(value)")
            return value != 0
        }
        return nil
    }
}
