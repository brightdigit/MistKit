//
//  RecordTypeSetTests.swift
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

internal import Testing

@testable import MistKit

@Suite("RecordTypeSet")
internal struct RecordTypeSetTests {
  @Test("forEach visits every record type in the pack")
  internal func forEachVisitsAllTypes() async {
    guard #available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *) else {
      Issue.record("RecordTypeSet is not available on this operating system.")
      return
    }

    let recordTypes = RecordTypeSet(TestRecord.self, AltTestRecord.self)
    var visited: [String] = []

    // swift-format-ignore: ReplaceForEachWithForLoop
    await recordTypes.forEach { recordType in
      visited.append(recordType.cloudKitRecordType)
    }

    #expect(visited.sorted() == ["AltTestRecord", "TestRecord"])
  }
}
