//
//  AsyncHelpersTests+FormatTimeout.swift
//  MistDemo
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

extension AsyncHelpersTests {
  @Suite("Format Timeout")
  internal struct FormatTimeout {
    @Test("formatTimeout with seconds")
    internal func formatSecondsTimeout() {
      #expect(formatTimeout(30) == "30 seconds")
      #expect(formatTimeout(45) == "45 seconds")
    }

    @Test("formatTimeout with single minute")
    internal func formatSingleMinute() {
      #expect(formatTimeout(60) == "1 minute")
    }

    @Test("formatTimeout with multiple minutes")
    internal func formatMultipleMinutes() {
      #expect(formatTimeout(120) == "2 minutes")
      #expect(formatTimeout(300) == "5 minutes")
    }

    @Test("formatTimeout with fractional seconds under 60")
    internal func formatFractionalSeconds() {
      #expect(formatTimeout(15.5) == "15 seconds")
      #expect(formatTimeout(59.9) == "59 seconds")
    }

    @Test("formatTimeout with fractional minutes")
    internal func formatFractionalMinutes() {
      #expect(formatTimeout(90) == "1 minute")
      #expect(formatTimeout(150) == "2 minutes")
    }
  }
}
