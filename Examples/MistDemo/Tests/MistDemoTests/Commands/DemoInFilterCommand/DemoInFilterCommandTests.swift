//
//  DemoInFilterCommandTests.swift
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

import Foundation
import Testing

@testable import MistDemoKit

@Suite("DemoInFilterCommand")
internal struct DemoInFilterCommandTests {
  @Test("Static command identity")
  internal func staticIdentity() {
    #expect(DemoInFilterCommand.commandName == "demo-in-filter")
    #expect(
      DemoInFilterCommand.abstract
        == "Demonstrates IN/NOT_IN QueryFilter against CloudKit"
    )
    #expect(DemoInFilterCommand.helpText.contains("DEMO-IN-FILTER"))
    #expect(DemoInFilterCommand.helpText.contains("IN filter for [10, 30]"))
  }

  @Test("Initializes with a base configuration without throwing")
  internal func initializesWithConfig() async throws {
    let baseConfig = try await MistDemoConfig()
    let command = DemoInFilterCommand(config: baseConfig)
    _ = command
  }
}
