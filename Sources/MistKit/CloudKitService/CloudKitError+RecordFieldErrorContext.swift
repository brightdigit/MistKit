//
//  CloudKitError+RecordFieldErrorContext.swift
//  MistKit
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

internal import Foundation
internal import OpenAPIRuntime

extension CloudKitError: RecordFieldErrorContext {
  /// The record the error is about: the record of an
  /// ``invalidFieldValue(recordName:fieldName:underlying:)`` or of a
  /// ``recordOperationFailed(_:)``.
  ///
  /// ``modifyIncomplete(completed:unsent:underlying:)`` reads through to its
  /// `underlying` error.
  public var recordName: String? {
    switch self {
    case .invalidFieldValue(let recordName, _, _):
      recordName
    case .recordOperationFailed(let failure):
      failure.recordName
    case .modifyIncomplete(_, _, let underlying):
      underlying.recordName
    default:
      nil
    }
  }

  /// The field the error is about: the field of an
  /// ``invalidFieldValue(recordName:fieldName:underlying:)`` or of a
  /// ``conversionFailed(_:)`` that names one.
  ///
  /// ``modifyIncomplete(completed:unsent:underlying:)`` reads through to its
  /// `underlying` error.
  public var fieldName: String? {
    switch self {
    case .invalidFieldValue(_, let fieldName, _):
      fieldName
    case .conversionFailed(let error):
      error.fieldName
    case .modifyIncomplete(_, _, let underlying):
      underlying.fieldName
    default:
      nil
    }
  }

  /// ``invalidFieldValue(recordName:fieldName:underlying:)`` for the error
  /// `JSONEncoder` threw while encoding records, or `nil` when it isn't about
  /// a record's field.
  ///
  /// `JSONEncoder` refuses a `NaN` or infinite number with
  /// `EncodingError.invalidValue`. Its coding path holds the record's index,
  /// then `fields`, then the field name, for each of the shapes MistKit
  /// writes:
  ///
  /// - `[WireRecord]` (Copy As JSON) and any payload holding one
  ///   (`{"records": [WireRecord]}`).
  /// - ``ModifyRecordsRequestBody`` and the `records/modify` body
  ///   ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)``
  ///   sends.
  ///
  /// The index is the last array index before `fields`; a path with none (a
  /// single record) is index 0 when there's one record name.
  ///
  /// - Parameters:
  ///   - error: What encoding threw. An OpenAPIRuntime `ClientError` is
  ///     unwrapped.
  ///   - recordNames: The encoded records' names, in encoding order; `nil` for
  ///     a record without one.
  public init?(encodingError error: any Error, recordNames: [String?]) {
    let inspected = (error as? ClientError)?.underlyingError ?? error
    guard let encodingError = inspected as? EncodingError,
      case .invalidValue(_, let context) = encodingError
    else {
      return nil
    }
    let path = context.codingPath
    guard
      let fieldsIndex = path.firstIndex(where: {
        $0.intValue == nil && $0.stringValue == "fields"
      }),
      path.indices.contains(fieldsIndex + 1)
    else {
      return nil
    }
    let index =
      path[..<fieldsIndex].last { $0.intValue != nil }?.intValue
      ?? (recordNames.count == 1 ? 0 : nil)
    let recordName = index.flatMap { recordNames.indices.contains($0) ? recordNames[$0] : nil }
    self = .invalidFieldValue(
      recordName: recordName,
      fieldName: path[fieldsIndex + 1].stringValue,
      underlying: encodingError
    )
  }
}
