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

  /// `POST /api/zones/list` — every zone in the target database. Carries only
  /// the database selector; `zones/list` (GET in CloudKit Web Services) takes
  /// no further input.
  internal struct ListZones: Decodable {
    private enum CodingKeys: String, CodingKey {
      case database
    }

    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/zones/lookup` — resolve specific zones by name. The browser
  /// sends bare zone names; the backend maps them to `ZoneID` values.
  internal struct LookupZones: Decodable {
    private enum CodingKeys: String, CodingKey {
      case zoneNames
      case database
    }

    internal let zoneNames: [String]
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.zoneNames =
        try container.decodeIfPresent([String].self, forKey: .zoneNames) ?? []
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/zones/changes` — database-level zone changes since an optional
  /// continuation `syncToken`. Backed by `changes/database`, the current
  /// replacement for the deprecated `zones/changes` operation.
  internal struct ZoneChanges: Decodable {
    private enum CodingKeys: String, CodingKey {
      case syncToken
      case database
    }

    internal let syncToken: String?
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.syncToken = try container.decodeIfPresent(
        String.self, forKey: .syncToken
      )
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/changes/zone` — record changes within one or more zones.
  /// Each entry may carry its own continuation `syncToken`; a bare zone name
  /// defaults to an initial fetch of that zone.
  internal struct ZoneRecordChanges: Decodable {
    /// A single requested zone, with its own optional `syncToken`.
    internal struct ZoneRequest: Decodable, Sendable {
      internal let zoneName: String
      internal let syncToken: String?
    }

    private enum CodingKeys: String, CodingKey {
      case zones
      case database
    }

    internal let zones: [ZoneRequest]
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.zones =
        try container.decodeIfPresent([ZoneRequest].self, forKey: .zones) ?? []
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }
}
