//
//  ModifyOperationInputTests.swift
//  MistDemoTests
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

import MistKit
import Testing

@testable import MistDemoKit

@Suite("ModifyOperationInput Validation Tests")
internal struct ModifyOperationInputTests {
  @Test("update requires a recordName")
  internal func updateRequiresRecordName() throws {
    let input = ModifyOperationInput(operation: .update, recordType: "Note", recordName: nil)

    #expect(throws: ModifyError.self) {
      _ = try input.toRecordOperation(index: 0)
    }
  }

  @Test("delete requires a recordName")
  internal func deleteRequiresRecordName() throws {
    let input = ModifyOperationInput(operation: .delete, recordType: "Note", recordName: nil)

    #expect(throws: ModifyError.self) {
      _ = try input.toRecordOperation(index: 0)
    }
  }

  @Test("create succeeds without a recordName")
  internal func createWithoutRecordName() throws {
    let input = ModifyOperationInput(operation: .create, recordType: "Note", recordName: nil)
    let operation = try input.toRecordOperation(index: 0)

    #expect(operation.recordName == nil)
    #expect(operation.recordType == "Note")
  }
}
