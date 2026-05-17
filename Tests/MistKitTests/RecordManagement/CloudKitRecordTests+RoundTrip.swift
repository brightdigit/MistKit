//
//  CloudKitRecordTests+RoundTrip.swift
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
  @Suite("Round-Trip Conversion")
  internal struct RoundTrip {
    @Test("Round-trip: record -> fields -> record")
    internal func roundTripConversion() {
      let original = TestRecord(
        recordName: "test-8",
        name: "Round Trip",
        count: 50,
        isActive: true,
        score: 88.8,
        lastUpdated: Date()
      )

      let fields = original.toCloudKitFields()
      let recordInfo = RecordInfo(
        recordName: original.recordName,
        recordType: TestRecord.cloudKitRecordType,
        fields: fields
      )

      let reconstructed = TestRecord.from(recordInfo: recordInfo)

      #expect(reconstructed?.recordName == original.recordName)
      #expect(reconstructed?.name == original.name)
      #expect(reconstructed?.count == original.count)
      #expect(reconstructed?.isActive == original.isActive)
      #expect(reconstructed?.score == original.score)
    }
  }
}
