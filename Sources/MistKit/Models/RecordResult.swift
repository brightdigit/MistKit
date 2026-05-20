//
//  RecordResult.swift
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

public import MistKitOpenAPI

/// The outcome of a single operation in a `modifyRecords` or `lookupRecords`
/// batch.
///
/// CloudKit returns per-operation results inline in the response `records`
/// array: a successful operation yields a record, while a failed one yields an
/// error describing what went wrong. `RecordResult` models that union so no
/// per-record failure is silently dropped.
///
/// ```swift
/// let results = try await service.modifyRecords(operations, database: .private)
/// for result in results {
///   switch result {
///   case .success(let record): print("saved \(record.recordName)")
///   case .failure(let error):  print("failed \(error.recordName): \(error.serverErrorCode.rawValue)")
///   }
/// }
/// ```
public enum RecordResult: Sendable {
  /// The operation succeeded and CloudKit returned the resulting record.
  case success(RecordInfo)
  /// The operation failed; the associated ``RecordError`` describes the failure.
  case failure(RecordError)

  /// The record for a successful result, or `nil` for a failure.
  public var record: RecordInfo? {
    guard case .success(let record) = self else {
      return nil
    }
    return record
  }

  /// The error for a failed result, or `nil` for a success.
  public var error: RecordError? {
    guard case .failure(let error) = self else {
      return nil
    }
    return error
  }

  internal init(from item: Components.Schemas.ModifyResponse.recordsPayloadPayload) throws {
    switch item {
    case .RecordError(let error):
      self = .failure(error)
    case .RecordResponse(let record):
      self = .success(try RecordInfo(from: record))
    }
  }

  internal init(from item: Components.Schemas.LookupResponse.recordsPayloadPayload) throws {
    switch item {
    case .RecordError(let error):
      self = .failure(error)
    case .RecordResponse(let record):
      self = .success(try RecordInfo(from: record))
    }
  }

  /// Returns the record for a successful result, or throws
  /// ``CloudKitError/recordOperationFailed(_:)`` for a failure.
  public func get() throws(CloudKitError) -> RecordInfo {
    switch self {
    case .success(let record):
      return record
    case .failure(let error):
      throw CloudKitError.recordOperationFailed(error)
    }
  }
}
