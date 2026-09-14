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

internal import Foundation
internal import MistKitOpenAPI
internal import Testing

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
      fields: ["title": .string(.value("Test"))]
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
        "title": .string(.value("Hello")),
        "count": .int64(.value(42)),
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
      fields: ["title": .string(.value("Updated"))],
      recordChangeTag: "abc123"
    )

    let apiOperation = try Components.Schemas.RecordOperation(from: operation)
    #expect(apiOperation.record?.recordChangeTag == "abc123")
  }

  @Test("Conversion sets isEncrypted on named encrypted fields")
  internal func conversionSetsIsEncrypted() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("RecordOperation conversion is not available on this operating system.")
      return
    }
    let operation = RecordOperation(
      operationType: .create,
      recordType: "TestRecord",
      recordName: "enc-1",
      fields: [
        "title": .string(.value("plain")),
        "secret": .string(.value("hidden")),
      ],
      encryptedFields: ["secret"]
    )

    let apiOperation = try Components.Schemas.RecordOperation(from: operation)
    let fields = apiOperation.record?.fields?.additionalProperties
    #expect(fields?["secret"]?.isEncrypted == true)
    #expect(fields?["title"]?.isEncrypted == nil)
  }

  /// Verified live: an encrypted field sent without `type` is read by CloudKit
  /// as ENCRYPTED_BYTES and rejected with BAD_REQUEST, so every encrypted
  /// field must carry an explicit tag even where a plain write would not.
  @Test("Conversion tags encrypted fields with an explicit type")
  internal func conversionTagsEncryptedFieldTypes() throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("RecordOperation conversion is not available on this operating system.")
      return
    }
    let operation = RecordOperation(
      operationType: .create,
      recordType: "TestRecord",
      recordName: "enc-2",
      fields: [
        "title": .string(.value("plain")),
        "secret": .string(.value("hidden")),
        "count": .int64(.value(7)),
        "tags": .string(.list(["a", "b"])),
        "ratio": .double(.value(0.5)),
      ],
      encryptedFields: ["secret", "count", "tags", "ratio"]
    )

    let apiOperation = try Components.Schemas.RecordOperation(from: operation)
    let fields = apiOperation.record?.fields?.additionalProperties
    #expect(fields?["secret"]?._type == .STRING)
    #expect(fields?["count"]?._type == .INT64)
    #expect(fields?["tags"]?._type == .STRING_LIST)
    #expect(fields?["ratio"]?._type == .DOUBLE)
    // Plain fields keep the inference-friendly untagged form.
    #expect(fields?["title"]?._type == nil)
  }
}
