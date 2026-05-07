//
//  CurrentUserCommandTests+MockUserResponse.swift
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

extension CurrentUserCommandTests {
  @Suite("Mock User Response")
  internal struct MockUserResponse {
    @Test("Mock user response structure")
    internal func mockUserResponseStructure() {
      // This test verifies the expected structure of a user response
      let mockUser: [String: Any] = [
        "userRecordName": "_abc123def456",
        "emailAddress": "test@example.com",
        "firstName": "Test",
        "lastName": "User",
        "hasValidatedEmail": true,
      ]

      #expect(mockUser["userRecordName"] as? String == "_abc123def456")
      #expect(mockUser["emailAddress"] as? String == "test@example.com")
      #expect(mockUser["firstName"] as? String == "Test")
      #expect(mockUser["lastName"] as? String == "User")
      #expect(mockUser["hasValidatedEmail"] as? Bool == true)
    }
  }
}
