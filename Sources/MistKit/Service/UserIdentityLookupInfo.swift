//
//  UserIdentityLookupInfo.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

/// Information used to look up a user identity from CloudKit
public struct UserIdentityLookupInfo: Codable, Sendable {
  /// The email address to look up
  public let emailAddress: String?
  /// The phone number to look up
  public let phoneNumber: String?
  /// The user record name to look up
  public let userRecordName: String?

  internal init(from schema: Components.Schemas.UserIdentityLookupInfo) {
    self.emailAddress = schema.emailAddress
    self.phoneNumber = schema.phoneNumber
    self.userRecordName = schema.userRecordName
  }

  /// Initialize lookup info with optional identifiers
  /// - Parameters:
  ///   - emailAddress: The email address to look up
  ///   - phoneNumber: The phone number to look up
  ///   - userRecordName: The user record name to look up
  public init(
    emailAddress: String? = nil,
    phoneNumber: String? = nil,
    userRecordName: String? = nil
  ) {
    self.emailAddress = emailAddress
    self.phoneNumber = phoneNumber
    self.userRecordName = userRecordName
  }
}
