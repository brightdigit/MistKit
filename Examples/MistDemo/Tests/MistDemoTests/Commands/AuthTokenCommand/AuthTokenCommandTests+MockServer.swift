//
//  AuthTokenCommandTests+MockServer.swift
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

#if canImport(Hummingbird)
  import Foundation
  import Testing

  @testable import MistDemoKit

  extension AuthTokenCommandTests {
    @Suite("Mock Server")
    internal struct MockServer {
      @Test("AuthRequest decodes correctly")
      internal func authRequestDecodesCorrectly() throws {
        let json = """
          {
            "sessionToken": "mock-session-token",
            "userRecordName": "user123"
          }
          """

        let data = Data(json.utf8)
        let request = try JSONDecoder().decode(AuthRequest.self, from: data)

        #expect(request.sessionToken == "mock-session-token")
        #expect(request.userRecordName == "user123")
      }

      @Test("AuthResponse encodes correctly")
      internal func authResponseEncodesCorrectly() throws {
        let response = AuthResponse(
          userRecordName: "user123",
          cloudKitData: CloudKitData(user: nil, zones: [], error: nil),
          message: "Success"
        )

        let data = try JSONEncoder().encode(response)

        // Verify the encoded data is not empty
        #expect(!data.isEmpty)
      }
    }
  }
#endif
