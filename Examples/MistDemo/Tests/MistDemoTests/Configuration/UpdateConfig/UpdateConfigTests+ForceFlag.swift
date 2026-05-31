//
//  UpdateConfigTests+ForceFlag.swift
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
  @Suite("Force Flag")
  internal struct ForceFlag {
    @Test("UpdateConfig defaults force to false")
    internal func forceDefaultsFalse() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordName: "rec1")

      #expect(config.force == false)
    }

    @Test("UpdateConfig accepts force=true")
    internal func forceCanBeTrue() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordName: "rec1", force: true)

      #expect(config.force == true)
    }

    @Test("UpdateConfig preserves recordChangeTag when force is set (caller decides effect)")
    internal func forceWithChangeTagBothPreserved() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(
        base: baseConfig,
        recordName: "rec1",
        recordChangeTag: "tag-1",
        force: true
      )

      // The Config holds both values; UpdateCommand decides to ignore the tag when force=true.
      #expect(config.recordChangeTag == "tag-1")
      #expect(config.force == true)
    }
  }
}
