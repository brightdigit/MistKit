//
//  WebJSONTests.swift
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

#if canImport(Hummingbird)
  import Foundation
  import Testing

  @testable import MistDemoKit

  @Suite("WebJSON")
  internal struct WebJSONTests {
    private struct DateWrapper: Codable {
      let date: Date
    }

    @Test("encoder writes Date as epoch-millis numbers")
    internal func encoderEmitsEpochMillis() throws {
      // 1500ms since 1970-01-01T00:00:00Z — chosen so the expected JSON
      // value is a plain integer the browser's `new Date(1500)` can consume.
      let date = Date(timeIntervalSince1970: 1.5)

      let data = try WebJSON.encoder().encode(DateWrapper(date: date))

      let json = try #require(
        try JSONSerialization.jsonObject(with: data) as? [String: Any]
      )
      #expect(json["date"] as? Double == 1_500)
    }
  }
#endif
