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

  /// Extract an Int64 value if this is an .int64 case
  var int64Value: Int? {
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
}
