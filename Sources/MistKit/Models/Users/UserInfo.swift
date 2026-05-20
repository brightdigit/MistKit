//
//  UserInfo.swift
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

internal import MistKitOpenAPI

/// User information from CloudKit (User Dictionary — returned by `users/caller` and `users/lookup/*`).
public struct UserInfo: Encodable, Sendable {
  /// The user's record name
  public let userRecordName: String
  /// The user's first name
  public let firstName: String?
  /// The user's last name
  public let lastName: String?
  /// The user's email address
  public let emailAddress: String?

  /// Create a `UserInfo` directly.
  ///
  /// Primarily for testing and manual construction; instances returned by
  /// CloudKit operations are built from the response internally.
  ///
  /// - Parameters:
  ///   - userRecordName: The user's record name.
  ///   - firstName: The user's first name, if known.
  ///   - lastName: The user's last name, if known.
  ///   - emailAddress: The user's email address, if known.
  public init(
    userRecordName: String,
    firstName: String? = nil,
    lastName: String? = nil,
    emailAddress: String? = nil
  ) {
    self.userRecordName = userRecordName
    self.firstName = firstName
    self.lastName = lastName
    self.emailAddress = emailAddress
  }

  internal init(from cloudKitUser: Components.Schemas.UserResponse) throws {
    guard let userRecordName = cloudKitUser.userRecordName else {
      try CloudKitError.reportConversionFailure("UserResponse missing userRecordName")
    }
    self.userRecordName = userRecordName
    self.firstName = cloudKitUser.firstName
    self.lastName = cloudKitUser.lastName
    self.emailAddress = cloudKitUser.emailAddress
  }
}
