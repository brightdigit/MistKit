//
//  NamingStyleTests.swift
//  ConfigKeyKit
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

@testable import ConfigKeyKit

@Suite("NamingStyle Tests")
internal struct NamingStyleTests {
  @Test("Dot-separated style")
  internal func dotSeparatedStyle() {
    let style = StandardNamingStyle.dotSeparated
    #expect(style.transform("cloudkit.container_id") == "cloudkit.container_id")
  }

  @Test("Screaming snake case with prefix")
  internal func screamingSnakeCaseWithPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: "MYAPP")
    #expect(style.transform("cloudkit.container_id") == "MYAPP_CLOUDKIT_CONTAINER_ID")
  }

  @Test("Screaming snake case without prefix")
  internal func screamingSnakeCaseNoPrefix() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: nil)
    #expect(style.transform("cloudkit.container_id") == "CLOUDKIT_CONTAINER_ID")
  }

  @Test("Screaming snake case with nil prefix on shorter key")
  internal func screamingSnakeCaseNilPrefixShort() {
    let style = StandardNamingStyle.screamingSnakeCase(prefix: nil)
    #expect(style.transform("sync.verbose") == "SYNC_VERBOSE")
  }
}
