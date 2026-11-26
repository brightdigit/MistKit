//
//  CloudKitServiceTests.BatchChunking.ModifyAllRecords+NonFiniteParity.swift
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

extension CloudKitServiceTests.BatchChunking.ModifyAllRecords {
  /// A date that is finite but overflows to infinity in milliseconds.
  private static let overflowingDate = Date(timeIntervalSince1970: .greatestFiniteMagnitude)

  /// `modifyAllRecords` finds a non-finite number without encoding the
  /// request, so it must flag exactly what `JSONEncoder` refuses when the
  /// request is sent, naming the same record and field.
  @Test(
    "the non-finite check agrees with JSONEncoder on the converted request",
    arguments: [
      FieldValue.double(.value(.nan)),
      .double(.value(.infinity)),
      .double(.list([1, -.infinity])),
      .date(.value(overflowingDate)),
      .date(.list([Date(timeIntervalSince1970: 0), overflowingDate])),
      .location(.value(Location(latitude: .nan, longitude: 0))),
      .location(.value(Location(latitude: 0, longitude: .infinity))),
      .location(.value(Location(latitude: 0, longitude: 0, horizontalAccuracy: .nan))),
      .location(.value(Location(latitude: 0, longitude: 0, verticalAccuracy: .nan))),
      .location(.value(Location(latitude: 0, longitude: 0, altitude: -.infinity))),
      .location(.value(Location(latitude: 0, longitude: 0, speed: .nan))),
      .location(.value(Location(latitude: 0, longitude: 0, course: .infinity))),
      .location(.value(Location(latitude: 0, longitude: 0, timestamp: overflowingDate))),
      .location(.list([.init(latitude: 0, longitude: 0), .init(latitude: .nan, longitude: 1)])),
      // Finite values: neither flags them.
      .double(.value(1.5)),
      .double(.list([])),
      .date(.value(Date(timeIntervalSince1970: 1_700_000_000))),
      .location(.value(Location(latitude: 1, longitude: 2, speed: 3, timestamp: Date()))),
      .string(.value("x")),
      .int64(.list([1, 2])),
    ]
  )
  internal func nonFiniteCheckMatchesEncoder(_ value: FieldValue) throws {
    let operation = RecordOperation.create(
      recordType: "Note",
      recordName: "bad",
      fields: ["title": .string(.value("ok")), "score": value]
    )
    let checked = operation.nonFiniteFieldError()

    let encoded: CloudKitError?
    do {
      _ = try JSONEncoder.shared.encode([try Components.Schemas.RecordOperation(from: operation)])
      encoded = nil
    } catch {
      encoded = CloudKitError(encodingError: error, recordNames: ["bad"])
    }

    #expect((checked == nil) == (encoded == nil))
    #expect(checked?.recordName == encoded?.recordName)
    #expect(checked?.fieldName == encoded?.fieldName)
    if let checked {
      #expect(checked.recordName == "bad")
      #expect(checked.fieldName == "score")
    }
  }
}
