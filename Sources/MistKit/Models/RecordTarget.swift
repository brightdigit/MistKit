//
//  RecordTarget.swift
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

internal import MistKitOpenAPI

/// Phantom target tagging an ``OperationFailure`` (or ``OperationResult``) as
/// belonging to a per-record CloudKit batch (`modifyRecords` / `lookupRecords`).
public enum RecordTarget: OperationFailureTarget {
  /// Lifts a per-record failure into ``CloudKitError/recordOperationFailed(_:)``.
  public static func wrap(
    _ failure: OperationFailure<RecordTarget>
  ) -> CloudKitError {
    .recordOperationFailed(failure)
  }
}

extension OperationFailure where Target == RecordTarget {
  /// The record name of the record the operation failed on.
  ///
  /// A named alias for ``OperationFailure/identifier`` scoped to the
  /// record target, matching CloudKit's `recordName` wire field.
  public var recordName: String { identifier }

  internal init(from schema: Components.Schemas.RecordOperationFailure) {
    self.init(identifier: schema.value2.recordName, common: schema.value1)
  }
}

extension OperationResult where Success == RecordInfo, Target == RecordTarget {
  internal init(
    from item: Components.Schemas.ModifyResponse.recordsPayloadPayload
  ) throws(ConversionError) {
    switch item {
    case .RecordOperationFailure(let failure):
      self = .failure(OperationFailure(from: failure))
    case .RecordResponse(let record):
      self = .success(try RecordInfo(from: record))
    }
  }

  internal init(
    from item: Components.Schemas.LookupResponse.recordsPayloadPayload
  ) throws(ConversionError) {
    switch item {
    case .RecordOperationFailure(let failure):
      self = .failure(OperationFailure(from: failure))
    case .RecordResponse(let record):
      self = .success(try RecordInfo(from: record))
    }
  }
}
