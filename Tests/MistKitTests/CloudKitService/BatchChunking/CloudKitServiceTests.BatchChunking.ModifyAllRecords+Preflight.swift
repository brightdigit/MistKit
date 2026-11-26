//
//  CloudKitServiceTests.BatchChunking.ModifyAllRecords+Preflight.swift
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
  /// An operation `modifyRecords` rejects before sending, in a later request,
  /// must stop `modifyAllRecords` before the first request is sent.
  @Test("an encrypted reference in a later request stops the call before any request is sent")
  internal func laterRequestFailsClientCheck() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("CloudKitService is not available on this operating system.")
      return
    }
    let provider = await Self.provider([try Self.modified(["n0", "n1"])])
    let service = try CloudKitServiceTests.BatchChunking.makeUserService(provider: provider)
    // Sent as [n0 n1], [n2 n3], [n4]; n3 marks a reference encrypted, which
    // CloudKit doesn't allow.
    let operations = Self.names("n", 5).map { name in
      ZonedRecordOperation(
        name == "n3"
          ? .create(
            recordType: "Note",
            recordName: name,
            fields: ["owner": .reference(.value(Reference(recordName: "owner")))],
            encryptedFields: ["owner"]
          )
          : .create(recordType: "Note", recordName: name, fields: ["title": .string(.value(name))])
      )
    }

    let failure = try await Self.incomplete(operations, service: service)

    #expect(failure.completed.isEmpty)
    #expect(Self.recordNames(failure.unsent) == ["n0", "n1", "n2", "n3", "n4"])
    guard case .badRequest = failure.underlying else {
      Issue.record("expected .badRequest, got \(failure.underlying)")
      return
    }
    #expect(await provider.callCount(for: Self.operationID) == 0)
  }
}
