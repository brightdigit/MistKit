//
//  WebRequests+Shares.swift
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

// Sharing routes have no `database` field: `resolveShares` / `acceptShares`
// operate on the public database with web-auth credentials regardless of
// the request's selected database.
extension WebRequests {
  /// `POST /api/records/resolve` and `POST /api/records/accept` — resolve or
  /// accept shares identified by short GUID.
  internal struct ResolveOrAcceptShares: Decodable {
    private enum CodingKeys: String, CodingKey {
      case shortGUIDs
      case fetchRootRecord
      case fields
    }

    internal let shortGUIDs: [String]
    internal let fetchRootRecord: Bool?
    internal let fields: [String]?

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.shortGUIDs =
        try container.decodeIfPresent([String].self, forKey: .shortGUIDs) ?? []
      self.fetchRootRecord = try container.decodeIfPresent(
        Bool.self, forKey: .fetchRootRecord
      )
      self.fields = try container.decodeIfPresent(
        [String].self, forKey: .fields
      )
    }
  }
}
