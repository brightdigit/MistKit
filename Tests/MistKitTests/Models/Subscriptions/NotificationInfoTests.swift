//
//  NotificationInfoTests.swift
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

internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

@Suite("NotificationInfo Conversion")
internal struct NotificationInfoTests {
  @Test("NotificationInfo round-trips through the OpenAPI schema")
  internal func roundTrip() {
    let info = NotificationInfo(
      alertBody: "Hello",
      alertLocalizationKey: "GREETING",
      alertLocalizationArgs: ["Leo"],
      soundName: "default",
      shouldBadge: true,
      shouldSendContentAvailable: false,
      additionalFields: ["title"],
      category: "article"
    )

    let schema = info.schema
    #expect(schema.alertBody == "Hello")
    #expect(schema.alertLocalizationKey == "GREETING")
    #expect(schema.alertLocalizationArgs == ["Leo"])
    #expect(schema.soundName == "default")
    #expect(schema.shouldBadge == true)
    #expect(schema.shouldSendContentAvailable == false)
    #expect(schema.additionalFields == ["title"])
    #expect(schema.category == "article")

    let recovered = NotificationInfo(from: schema)
    #expect(recovered == info)
  }

  @Test("Absent notification flags stay nil through the schema")
  internal func absentFlagsStayNil() {
    let info = NotificationInfo(alertBody: "Ping")
    let schema = info.schema

    #expect(schema.shouldBadge == nil)
    #expect(schema.shouldSendContentAvailable == nil)

    let recovered = NotificationInfo(from: schema)
    #expect(recovered.shouldBadge == nil)
    #expect(recovered.shouldSendContentAvailable == nil)
    #expect(recovered.alertBody == "Ping")
  }
}
