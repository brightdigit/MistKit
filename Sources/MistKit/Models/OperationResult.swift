//
//  OperationResult.swift
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

/// The outcome of a single operation in a CloudKit batch.
///
/// CloudKit returns per-operation results inline in modify/lookup response
/// arrays: a successful operation yields the new item, while a failed one
/// yields an error describing what went wrong. `OperationResult` models that
/// union so no per-item failure is silently dropped.
///
/// Not built on `Swift.Result` because that requires `Failure: Error`, but
/// ``OperationFailure`` is intentionally a data payload — surfaced as data in
/// batch results and wrapped in ``CloudKitError`` only when a single-item
/// convenience method needs to throw.
///
/// ```swift
/// let results = try await service.modifyRecords(operations, database: .private)
/// for result in results {
///   switch result {
///   case .success(let record): print("saved \(record.recordName)")
///   case .failure(let error):  print("failed \(error.identifier): \(error.serverErrorCode.rawValue)")
///   }
/// }
/// ```
public enum OperationResult<Success: Sendable, Target: OperationFailureTarget>: Sendable {
  /// The operation succeeded and CloudKit returned the resulting item.
  case success(Success)
  /// The operation failed; the associated ``OperationFailure`` describes
  /// the failure.
  case failure(OperationFailure<Target>)

  /// Returns the successful value, or throws the failure wrapped in its
  /// target's ``CloudKitError`` case (``CloudKitError/recordOperationFailed(_:)``
  /// for records, ``CloudKitError/subscriptionOperationFailed(_:)`` for
  /// subscriptions).
  public func get() throws(CloudKitError) -> Success {
    switch self {
    case .success(let value):
      return value
    case .failure(let failure):
      throw Target.wrap(failure)
    }
  }
}
