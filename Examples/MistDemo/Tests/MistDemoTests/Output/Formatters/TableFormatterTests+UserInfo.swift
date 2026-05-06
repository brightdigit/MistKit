//
//  TableFormatterTests+UserInfo.swift
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
import MistKit
import Testing

@testable import MistDemoKit

extension TableFormatterTests {
  @Suite("UserInfo")
  internal struct UserInfoFormat {
    @Test("Format basic UserInfo")
    internal func formatBasicUser() throws {
      let user = UserInfo.test(
        userRecordName: "user-001",
        firstName: "John",
        lastName: "Doe",
        emailAddress: "john.doe@example.com"
      )
      let formatter = TableFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("User Record Name: user-001"))
      #expect(output.contains("First Name: John"))
      #expect(output.contains("Last Name: Doe"))
      #expect(output.contains("Email: john.doe@example.com"))
    }

    @Test("Format UserInfo with minimal fields")
    internal func formatUserWithMinimalFields() throws {
      let user = UserInfo.test(userRecordName: "user-min")
      let formatter = TableFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("User Record Name: user-min"))
      #expect(!output.contains("First Name:"))
      #expect(!output.contains("Last Name:"))
      #expect(!output.contains("Email:"))
    }

    @Test("Format UserInfo with partial fields")
    internal func formatUserWithPartialFields() throws {
      let user = UserInfo.test(
        userRecordName: "user-002",
        firstName: "Jane",
        emailAddress: "jane@example.com"
      )
      let formatter = TableFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("User Record Name: user-002"))
      #expect(output.contains("First Name: Jane"))
      #expect(!output.contains("Last Name:"))
      #expect(output.contains("Email: jane@example.com"))
    }

    @Test("Format UserInfo with newlines in fields")
    internal func formatUserWithNewlinesInFields() throws {
      let user = UserInfo.test(
        userRecordName: "user-003",
        firstName: "John\nJacob",
        lastName: "Smith\nJones"
      )
      let formatter = TableFormatter()

      let output = try formatter.format(user)

      // Newlines should be converted to spaces
      #expect(output.contains("First Name: John Jacob"))
      #expect(output.contains("Last Name: Smith Jones"))
    }

    @Test("Format UserInfo with special characters")
    internal func formatUserWithSpecialChars() throws {
      let user = UserInfo.test(
        userRecordName: "user-004",
        firstName: "O'Brien",
        lastName: "Müller"
      )
      let formatter = TableFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("First Name: O'Brien"))
      #expect(output.contains("Last Name: Müller"))
    }
  }
}
