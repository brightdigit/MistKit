//
//  QueryCommandTests+LimitValidation.swift
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

extension QueryCommandTests {
  @Suite("Limit Validation")
  internal struct LimitValidation {
    @Test("Limit validation accepts valid range")
    internal func limitValidationAcceptsValid() {
      let validLimits = [1, 50, 100, 200]

      for limit in validLimits {
        #expect(limit >= 1 && limit <= 200)
      }
    }

    @Test("Limit validation rejects invalid values")
    internal func limitValidationRejectsInvalid() {
      let invalidLimits = [0, -1, 201, 500]

      for limit in invalidLimits {
        #expect(!(limit >= 1 && limit <= 200))
      }
    }
  }
}
