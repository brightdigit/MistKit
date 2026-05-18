//
//  UpdateConfigTests+BasicInitialization.swift
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
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension UpdateConfigTests {
  @Suite("Basic Initialization")
  internal struct BasicInitialization {
    @Test("UpdateConfig initializes with defaults")
    internal func initializeWithDefaults() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordName: "rec1")

      #expect(config.recordName == "rec1")
      #expect(config.zone == "_defaultZone")
      #expect(config.recordType == "Note")
      #expect(config.recordChangeTag == nil)
      #expect(config.force == false)
      #expect(config.fields.isEmpty)
      #expect(config.output == .json)
    }

    @Test("UpdateConfig initializes with custom zone")
    internal func initializeWithCustomZone() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, zone: "customZone", recordName: "rec1")

      #expect(config.zone == "customZone")
    }

    @Test("UpdateConfig initializes with custom record type")
    internal func initializeWithCustomRecordType() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordType: "Article", recordName: "rec1")

      #expect(config.recordType == "Article")
    }

    @Test("UpdateConfig initializes with record change tag")
    internal func initializeWithRecordChangeTag() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(
        base: baseConfig,
        recordName: "rec1",
        recordChangeTag: "tag-abc123"
      )

      #expect(config.recordChangeTag == "tag-abc123")
    }

    @Test("UpdateConfig initializes without record change tag")
    internal func initializeWithoutRecordChangeTag() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordName: "rec1", recordChangeTag: nil)

      #expect(config.recordChangeTag == nil)
    }
  }
}
