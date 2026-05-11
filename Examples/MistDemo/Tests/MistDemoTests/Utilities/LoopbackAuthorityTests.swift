//
//  LoopbackAuthorityTests.swift
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

import Testing

@testable import MistDemoKit

@Suite("LoopbackAuthority Tests")
internal struct LoopbackAuthorityTests {
  @Test(
    "Accepts recognized loopback authorities",
    arguments: [
      "localhost",
      "127.0.0.1",
      "[::1]",
      "localhost:8080",
      "127.0.0.1:8080",
      "[::1]:8080",
    ]
  )
  internal func accepts(authority: String) {
    #expect(LoopbackAuthority.isLoopback(authority))
  }

  @Test(
    "Rejects non-loopback authorities",
    arguments: [
      "",
      "evil.com",
      "evil.com:8080",
      "example.com",
      "example.com:443",
      "api.apple-cloudkit.com",
      "localhost.evil.com",
      "localhost.evil.com:8080",
      "localhostx",
      "127.0.0.1.evil.com",
      "127.0.0.1.evil.com:8080",
      "127.0.0.2",
      "10.0.0.1",
      "10.0.0.1:8080",
      "192.168.1.1:8080",
      "0.0.0.0",
      "[::2]",
      "[2001:db8::1]",
      "[2001:db8::1]:8080",
      "[::1].evil.com",
    ]
  )
  internal func rejects(authority: String) {
    #expect(!LoopbackAuthority.isLoopback(authority))
  }

  @Test("Rejects malformed bracketed IPv6 (missing closing bracket)")
  internal func malformedMissingCloseBracket() {
    #expect(!LoopbackAuthority.isLoopback("[::1"))
  }

  @Test("Rejects bracketed IPv6 with trailing junk instead of port")
  internal func malformedTrailingJunk() {
    #expect(!LoopbackAuthority.isLoopback("[::1]junk"))
  }
}
