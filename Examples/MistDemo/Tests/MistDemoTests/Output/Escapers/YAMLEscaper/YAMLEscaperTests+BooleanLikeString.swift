//
//  YAMLEscaperTests+BooleanLikeString.swift
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

extension YAMLEscaperTests {
  @Suite("Boolean-like String (YAML Reserved Words)")
  internal struct BooleanLikeString {
    private let escaper = YAMLEscaper()

    @Test("String 'yes' is quoted")
    internal func yesIsQuoted() {
      let input = "yes"
      let output = escaper.escape(input)
      #expect(output == "\"yes\"")
    }

    @Test("String 'no' is quoted")
    internal func noIsQuoted() {
      let input = "no"
      let output = escaper.escape(input)
      #expect(output == "\"no\"")
    }

    @Test("String 'true' is quoted")
    internal func trueIsQuoted() {
      let input = "true"
      let output = escaper.escape(input)
      #expect(output == "\"true\"")
    }

    @Test("String 'false' is quoted")
    internal func falseIsQuoted() {
      let input = "false"
      let output = escaper.escape(input)
      #expect(output == "\"false\"")
    }

    @Test("String 'on' is quoted")
    internal func onIsQuoted() {
      let input = "on"
      let output = escaper.escape(input)
      #expect(output == "\"on\"")
    }

    @Test("String 'off' is quoted")
    internal func offIsQuoted() {
      let input = "off"
      let output = escaper.escape(input)
      #expect(output == "\"off\"")
    }

    @Test("String 'YES' (uppercase) is quoted")
    internal func yesUppercaseIsQuoted() {
      let input = "YES"
      let output = escaper.escape(input)
      #expect(output == "\"YES\"")
    }

    @Test("String 'True' (capitalized) is quoted")
    internal func trueCapitalizedIsQuoted() {
      let input = "True"
      let output = escaper.escape(input)
      #expect(output == "\"True\"")
    }
  }
}
