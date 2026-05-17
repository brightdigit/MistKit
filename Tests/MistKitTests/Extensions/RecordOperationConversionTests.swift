//
//  RecordOperationConversionTests.swift
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

import Foundation
internal import MistKitOpenAPI
import Testing

@testable import MistKit

@Suite("RecordOperation to OpenAPI Conversion")
internal struct RecordOperationConversionTests {
  @Test(
    "All operation types convert successfully",
    arguments: [
      RecordOperation.OperationType.create,
      RecordOperation.OperationType.update,
      RecordOperation.OperationType.forceUpdate,
      RecordOperation.OperationType.replace,
      RecordOperation.OperationType.forceReplace,
      RecordOperation.OperationType.delete,
      RecordOperation.OperationType.forceDelete,
    ]
  )
  internal func operationTypeConvertsSuccessfully(
    operationType: RecordOperation.OperationType
  ) throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("RecordOperation conversion is not available on this operating system.")
      return
    }
    let operation = RecordOperation(
      operationType: operationType,
      recordType: "TestRecord",
      recordName: "test-record-name",
      fields: ["title": .string("Test")]
    )

    let apiOperation = try Components.Schemas.RecordOperation(from: operation)
    #expect(apiOperation.record?.recordType == "TestRecord")
    #expect(apiOperation.record?.recordName == "test-record-name")
  }

  @Test("Conversion preserves record fields")
  internal func conversionPreservesFields() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("RecordOperation conversion is not available on this operating system.")
      return
    }
    let operation = RecordOperation(
      operationType: .create,
      recordType: "TestRecord",
      recordName: "test-name",
      fields: [
        "title": .string("Hello"),
        "count": .int64(42),
      ]
    )

    let apiOperation = try Components.Schemas.RecordOperation(from: operation)
    #expect(apiOperation.record?.fields?.additionalProperties.count == 2)
  }

  @Test("Conversion preserves recordChangeTag")
  internal func conversionPreservesChangeTag() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("RecordOperation conversion is not available on this operating system.")
      return
    }
    let operation = RecordOperation(
      operationType: .update,
      recordType: "TestRecord",
      recordName: "test-name",
      fields: ["title": .string("Updated")],
      recordChangeTag: "abc123"
    )

    let apiOperation = try Components.Schemas.RecordOperation(from: operation)
    #expect(apiOperation.record?.recordChangeTag == "abc123")
  }
}
