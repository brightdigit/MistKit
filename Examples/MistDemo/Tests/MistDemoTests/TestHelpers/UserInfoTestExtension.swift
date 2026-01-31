//
//  UserInfoTestExtension.swift
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

@testable import MistKit

/// Test extension for UserInfo to enable test instance creation
extension UserInfo {
  /// Create a test UserInfo instance
  ///
  /// Since UserInfo only has an internal initializer, this extension provides
  /// a way to create instances for testing purposes.
  ///
  /// - Parameters:
  ///   - userRecordName: The user's record name
  ///   - firstName: The user's first name
  ///   - lastName: The user's last name
  ///   - emailAddress: The user's email address
  /// - Returns: A UserInfo instance for testing
  static func test(
    userRecordName: String,
    firstName: String? = nil,
    lastName: String? = nil,
    emailAddress: String? = nil
  ) -> UserInfo {
    // Create a mock UserResponse to initialize UserInfo
    // Using @testable import allows access to internal types
    let userResponse = Components.Schemas.UserResponse(
      userRecordName: userRecordName,
      firstName: firstName,
      lastName: lastName,
      emailAddress: emailAddress
    )

    return UserInfo(from: userResponse)
  }
}
