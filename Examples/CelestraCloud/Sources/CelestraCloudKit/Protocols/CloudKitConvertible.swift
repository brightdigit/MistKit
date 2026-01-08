//
//  CloudKitConvertible.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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

/// Protocol for types that can be converted to/from CloudKit records using MistKit
///
/// Types conforming to this protocol can be:
/// - Converted to CloudKit field dictionaries for creating/updating records
/// - Initialized from CloudKit RecordInfo for reading records
///
/// This protocol standardizes the conversion pattern used throughout the codebase
/// and enables generic CloudKit operations.
public protocol CloudKitConvertible {
  /// Create an instance from a CloudKit record
  ///
  /// - Parameter record: The CloudKit RecordInfo containing field data
  /// - Throws: CloudKitConversionError if required fields are missing or invalid
  init(from record: RecordInfo) throws

  /// Convert the instance to a CloudKit fields dictionary
  ///
  /// - Returns: Dictionary mapping field names to FieldValue instances
  func toFieldsDict() -> [String: FieldValue]
}
