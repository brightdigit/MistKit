//
//  Components.Schemas.RecordOperation+MistKit.swift
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

/// Maps MistKit `RecordOperation.OperationType` to the OpenAPI generated payload.
///
/// Defined at file scope as a `private` free function so SwiftLint's
/// `type_contents_order` rule (which forbids type methods between initializers)
/// is satisfied without restructuring the extension.
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
// swiftlint:disable:next cyclomatic_complexity
private func apiOperationType(
  for operationType: RecordOperation.OperationType
) -> Components.Schemas.RecordOperation.operationTypePayload {
  switch operationType {
  case .create: return .create
  case .update: return .update
  case .forceUpdate: return .forceUpdate
  case .replace: return .replace
  case .forceReplace: return .forceReplace
  case .delete: return .delete
  case .forceDelete: return .forceDelete
  }
}

/// Extension to convert MistKit RecordOperation to OpenAPI Components.Schemas.RecordOperation
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Components.Schemas.RecordOperation {
  /// Initialize from MistKit RecordOperation
  internal init(from recordOperation: RecordOperation) {
    let apiFields = recordOperation.fields.mapValues {
      fieldValue -> Components.Schemas.FieldValueRequest in
      Components.Schemas.FieldValueRequest(from: fieldValue)
    }

    self.init(
      operationType: apiOperationType(for: recordOperation.operationType),
      record: .init(
        recordName: recordOperation.recordName,
        recordType: recordOperation.recordType,
        recordChangeTag: recordOperation.recordChangeTag,
        fields: .init(additionalProperties: apiFields)
      )
    )
  }
}
