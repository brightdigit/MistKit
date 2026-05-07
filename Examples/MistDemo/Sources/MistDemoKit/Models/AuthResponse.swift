//
//  AuthResponse.swift
//  MistDemo
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

/// Response model for authentication callback endpoints.
///
/// This model is returned by the AuthTokenCommand's Hummingbird routes after
/// processing CloudKit authentication callbacks. It provides comprehensive
/// feedback about the authentication result, including user information and
/// available zones.
///
/// - Note: Used in AuthTokenCommand.swift line 88 for route responses
internal struct AuthResponse: Encodable {
  /// The authenticated user's CloudKit record name.
  internal let userRecordName: String

  /// CloudKit data retrieved during authentication (user info and zones).
  internal let cloudKitData: CloudKitData

  /// Human-readable message describing the authentication result.
  internal let message: String
}
