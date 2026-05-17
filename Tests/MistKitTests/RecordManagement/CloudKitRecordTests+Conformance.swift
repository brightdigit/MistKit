//
//  CloudKitRecordTests+Conformance.swift
//  MistKit
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
import Testing

@testable import MistKit

extension CloudKitRecordTests {
  @Suite("Protocol Conformance")
  internal struct Conformance {
    @Test("CloudKitRecord conforms to Codable")
    internal func codableConformance() throws {
      let record = TestRecord(
        recordName: "test-9",
        name: "Codable Test",
        count: 123,
        isActive: true,
        score: 99.9,
        lastUpdated: Date()
      )

      let encoder = JSONEncoder()
      let data = try encoder.encode(record)

      let decoder = JSONDecoder()
      let decoded = try decoder.decode(TestRecord.self, from: data)

      #expect(decoded.recordName == record.recordName)
      #expect(decoded.name == record.name)
      #expect(decoded.count == record.count)
      #expect(decoded.isActive == record.isActive)
    }

    @Test("CloudKitRecord conforms to Sendable")
    internal func sendableConformance() async {
      let record = TestRecord(
        recordName: "test-10",
        name: "Sendable Test",
        count: 1,
        isActive: true,
        score: nil,
        lastUpdated: nil
      )

      // This test verifies that TestRecord (CloudKitRecord) is Sendable
      // by being able to pass it across async/await boundaries
      let task = Task {
        record.name
      }

      let name = await task.value
      #expect(name == "Sendable Test")
    }
  }
}
