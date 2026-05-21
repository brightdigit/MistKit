//
//  WebRequests+Zones.swift
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
internal import MistKit

extension WebRequests {
  /// `POST /api/zones/modify`
  ///
  /// Mirrors CloudKit Web Services `zones/modify`: a batch of create and/or
  /// delete operations against the target database. The browser sends each
  /// zone as `{ "zoneName": "X" }` (matching the CloudKit JS `RecordZone`
  /// shape), so both arrays decode through `ZoneRef`.
  ///
  /// `zones/modify` is unsupported on `.public` (it has only `_defaultZone`);
  /// the MistKit wrapper rejects that case, surfacing as a `500` error body.
  internal struct ModifyZones: Decodable {
    internal struct ZoneRef: Decodable, Sendable {
      internal let zoneName: String
    }

    private enum CodingKeys: String, CodingKey {
      case create
      case delete
      case database
    }

    internal let create: [ZoneRef]
    internal let delete: [ZoneRef]
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.create =
        try container.decodeIfPresent([ZoneRef].self, forKey: .create) ?? []
      self.delete =
        try container.decodeIfPresent([ZoneRef].self, forKey: .delete) ?? []
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }
}
