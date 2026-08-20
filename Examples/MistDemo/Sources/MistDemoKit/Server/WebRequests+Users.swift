//
//  WebRequests+Users.swift
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

internal import Foundation

// User-identity routes have no `database` field: the underlying MistKit
// wrapper (`discoverUserIdentities`) operates on the public database with
// web-auth credentials regardless of the request's selected database.
extension WebRequests {
  /// `POST /api/users/discover` — discover user identities by email address,
  /// phone number, and/or user record name. Any list may be omitted; an
  /// absent key decodes to an empty array.
  internal struct DiscoverUsers: Decodable {
    private enum CodingKeys: String, CodingKey {
      case emails
      case phoneNumbers
      case userRecordNames
    }

    internal let emails: [String]
    internal let phoneNumbers: [String]
    internal let userRecordNames: [String]

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.emails =
        try container.decodeIfPresent([String].self, forKey: .emails) ?? []
      self.phoneNumbers =
        try container.decodeIfPresent(
          [String].self, forKey: .phoneNumbers
        ) ?? []
      self.userRecordNames =
        try container.decodeIfPresent(
          [String].self, forKey: .userRecordNames
        ) ?? []
    }
  }
}
