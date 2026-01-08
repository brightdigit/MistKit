//
//  CloudKitErrorHandlingTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
import MistKit
import Testing

@testable import BushelCloudKit

// MARK: - CloudKit-Specific Error Handling Tests

@Suite("CloudKit Error Handling Tests")
internal struct CloudKitErrorHandlingTests {
  @Test("Quota exceeded error")
  internal func testQuotaExceeded() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.quotaExceeded)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "test",
      fields: TestFixtures.sonoma1421.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "RestoreImage")
      Issue.record("Expected quota exceeded error to be thrown")
    } catch let error as MockCloudKitError {
      if case .quotaExceeded = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Reference validation error")
  internal func testValidatingReferenceError() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.validatingReferenceError)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "XcodeVersion",
      recordName: "XcodeVersion-15C65",
      fields: TestFixtures.xcode151.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "XcodeVersion")
      Issue.record("Expected reference validation error to be thrown")
    } catch let error as MockCloudKitError {
      if case .validatingReferenceError = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Conflict error on duplicate create")
  internal func testConflictError() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.conflict)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "test",
      fields: TestFixtures.sonoma1421.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "RestoreImage")
      Issue.record("Expected conflict error to be thrown")
    } catch let error as MockCloudKitError {
      if case .conflict = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Unknown CloudKit error")
  internal func testUnknownError() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.unknownError("Something went wrong"))

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected unknown error to be thrown")
    } catch let error as MockCloudKitError {
      if case .unknownError(let message) = error {
        #expect(message == "Something went wrong")
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
