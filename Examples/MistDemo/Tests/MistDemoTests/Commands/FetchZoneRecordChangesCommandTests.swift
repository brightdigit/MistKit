//
//  FetchZoneRecordChangesCommandTests.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

@Suite("FetchZoneRecordChangesCommand Tests")
internal struct FetchZoneRecordChangesCommandTests {
  @Test("Command has correct static properties")
  internal func staticProperties() {
    #expect(FetchZoneRecordChangesCommand.commandName == "fetch-zone-record-changes")
    #expect(
      FetchZoneRecordChangesCommand.abstract
        == "Fetch record changes within one or more CloudKit zones"
    )
    #expect(
      FetchZoneRecordChangesCommand.helpText.contains("FETCH-ZONE-RECORD-CHANGES")
    )
  }

  @Test("Config defaults")
  internal func configDefaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(base: baseConfig)
    #expect(config.zones == ["_defaultZone"])
    #expect(config.fetchAll == false)
    #expect(config.output == .table)
  }
}
