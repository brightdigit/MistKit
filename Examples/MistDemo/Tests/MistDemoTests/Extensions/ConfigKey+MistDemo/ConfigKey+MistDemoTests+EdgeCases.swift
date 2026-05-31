//
//  ConfigKey+MistDemoTests+EdgeCases.swift
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

internal import ConfigKeyKit
internal import Foundation
internal import Testing

@testable import MistDemoKit

extension ConfigKeyMistDemoTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("ConfigKey with empty base string")
    internal func configKeyWithEmptyBase() {
      let key = ConfigKey(mistDemoPrefixed: "", default: "value")

      #expect(key.base?.isEmpty == true)
    }

    @Test("ConfigKey with dotted path")
    internal func configKeyWithDottedPath() {
      let key = ConfigKey(
        mistDemoPrefixed: "cloudkit.api.token",
        default: "default"
      )

      #expect(key.base == "cloudkit.api.token")
    }
  }
}
