//
//  CSVFormatterTests+UserInfo.swift
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

internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension CSVFormatterTests {
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
      let formatter = CSVFormatter()

      let output = try formatter.format(user)

      #expect(output.hasPrefix("Field,Value\n"))
      #expect(output.contains("userRecordName,user-001"))
      #expect(output.contains("firstName,John"))
      #expect(output.contains("lastName,Doe"))
      #expect(output.contains("emailAddress,john.doe@example.com"))
    }

    @Test("Format UserInfo with minimal fields")
    internal func formatUserWithMinimalFields() throws {
      let user = UserInfo.test(userRecordName: "user-min")
      let formatter = CSVFormatter()

      let output = try formatter.format(user)

      #expect(output.hasPrefix("Field,Value\n"))
      #expect(output.contains("userRecordName,user-min"))
      #expect(!output.contains("firstName"))
      #expect(!output.contains("lastName"))
      #expect(!output.contains("emailAddress"))

      // Should only have header + 1 line (userRecordName)
      let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
      #expect(lines.count == 2)
    }

    @Test("Format UserInfo with partial fields")
    internal func formatUserWithPartialFields() throws {
      let user = UserInfo.test(
        userRecordName: "user-002",
        firstName: "Jane"
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("userRecordName,user-002"))
      #expect(output.contains("firstName,Jane"))
      #expect(!output.contains("lastName"))
      #expect(!output.contains("emailAddress"))
    }

    @Test("Format UserInfo with special characters in name")
    internal func formatUserWithSpecialCharsInName() throws {
      let user = UserInfo.test(
        userRecordName: "user-003",
        firstName: "O'Brien",
        lastName: "Smith, Jr."
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("firstName,O'Brien"))
      #expect(output.contains("\"Smith, Jr.\""))
    }

    @Test("Format UserInfo with special characters in email")
    internal func formatUserWithSpecialCharsInEmail() throws {
      let user = UserInfo.test(
        userRecordName: "user-004",
        emailAddress: "test+tag@example.com"
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("emailAddress,test+tag@example.com"))
    }
  }
}
