//
//  CloudKitData.swift
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

import MistKit

/// CloudKit user and zone data for authentication response.
///
/// This model encapsulates CloudKit information retrieved during the
/// authentication flow, including user details and available zones.
/// It is used to serialize CloudKit information in auth flow responses.
///
/// - Note: Used in AuthResponse.swift line 13 for encoding auth response data
internal struct CloudKitData: Encodable {
  /// User information retrieved from CloudKit (nil if retrieval failed).
  internal let user: UserInfo?

  /// List of available zones in the user's container.
  internal let zones: [ZoneInfo]

  /// Error message if any part of the CloudKit data retrieval failed.
  internal let error: String?
}
