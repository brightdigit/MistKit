//
//  ManagementTokenTests.swift
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
internal import Testing

@testable import MistKit

@Suite("Management token")
internal struct ManagementTokenTests {
  @Test("Never reveals its value in text")
  internal func redacted() {
    let token = ManagementToken("super-secret")
    #expect(String(describing: token) == "ManagementToken(redacted)")
    #expect(String(reflecting: token) == "ManagementToken(redacted)")
    #expect(!"\(token)".contains("super-secret"))
  }

  @Test("Keeps its value for the request header")
  internal func value() {
    #expect(ManagementToken("abc").value == "abc")
  }

  @Test("Hides its value from dump and Mirror")
  internal func reflection() {
    let token = ManagementToken("super-secret")
    var dumped = ""
    dump(token, to: &dumped)
    #expect(!dumped.contains("super-secret"))
    #expect(Mirror(reflecting: token).children.isEmpty)
  }

  @Test("Compares by value")
  internal func hashable() {
    let first = ManagementToken("a")
    let same = ManagementToken("a")
    let other = ManagementToken("b")
    #expect(first == same)
    #expect(first != other)
    #expect(Set([first, same]).count == 1)
  }
}
