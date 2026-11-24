//
//  CloudKitServiceTests.BatchChunking.ModifyAllRecords+InvalidFieldValue.swift
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
internal import Testing

@testable import MistKit

extension CloudKitServiceTests.BatchChunking.ModifyAllRecords {
  /// A create of `name` setting `score`.
  private static func create(_ name: String, score: FieldValue) -> RecordOperation {
    .create(recordType: "Note", recordName: name, fields: ["score": score])
  }

  @Test(
    "a non-finite number fails modifyRecords with the record and field, unsent",
    arguments: [
      FieldValue.double(.value(.nan)),
      .double(.list([1, -.infinity])),
      .location(.value(Location(latitude: .nan, longitude: 0))),
      .location(.value(Location(latitude: 1, longitude: 2, speed: .infinity))),
    ]
  )
  internal func modifyRecordsNamesField(_ value: FieldValue) async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let provider = await Self.provider([try Self.modified(["ok", "bad"])])
    let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
    let operations = [
      Self.create("ok", score: .double(.value(1))),
      Self.create("bad", score: value),
    ]

    do {
      _ = try await service.modifyRecords(operations, database: .private)
      Issue.record("expected .invalidFieldValue")
    } catch {
      guard case .invalidFieldValue(let recordName, let fieldName, _) = error else {
        Issue.record("expected .invalidFieldValue, got \(error)")
        return
      }
      #expect(recordName == "bad")
      #expect(fieldName == "score")
      #expect(error.recordName == "bad")
      #expect(error.fieldName == "score")
    }
    #expect(await provider.callCount(for: Self.operationID) == 0)
  }

  @Test("a create CloudKit names reports the field without a record name")
  internal func unnamedCreate() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let provider = await Self.provider([])
    let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
    let operation = RecordOperation.create(
      recordType: "Note",
      fields: ["score": .double(.value(.infinity))]
    )

    do {
      _ = try await service.modifyRecords([operation], database: .private)
      Issue.record("expected .invalidFieldValue")
    } catch {
      #expect(error.recordName == nil)
      #expect(error.fieldName == "score")
    }
  }

  @Test("a non-finite number in a later request stops the call before any request is sent")
  internal func laterRequestNamesRecord() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let provider = await Self.provider([])
    let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
    // Sent as [n0 n1], [n2 n3], [n4]; n3 is the second operation of the
    // second request.
    let operations = Self.names("n", 5).map { name in
      ZonedRecordOperation(
        Self.create(name, score: .double(.value(name == "n3" ? .nan : 1)))
      )
    }

    let failure = try await Self.incomplete(operations, service: service)

    #expect(failure.completed.isEmpty)
    #expect(Self.recordNames(failure.unsent) == ["n0", "n1", "n2", "n3", "n4"])
    guard case .invalidFieldValue(let recordName, let fieldName, _) = failure.underlying else {
      Issue.record("expected .invalidFieldValue, got \(failure.underlying)")
      return
    }
    #expect(recordName == "n3")
    #expect(fieldName == "score")
    let error = CloudKitError.modifyIncomplete(
      completed: failure.completed,
      unsent: failure.unsent,
      underlying: failure.underlying
    )
    #expect(error.recordName == "n3")
    #expect(error.fieldName == "score")
    // Every request is encoded first, so none is sent.
    #expect(await provider.callCount(for: Self.operationID) == 0)
  }
}
