//
//  WebRequests.swift
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

/// Request payloads for the web command's CRUD endpoints.
///
/// `fields` decodes directly into MistKit's `FieldValue`, which has a custom
/// Codable that accepts raw JSON primitives (string → `.string`, integer →
/// `.int64`, floating-point → `.double`) along with the complex CloudKit
/// shapes (location, reference, asset, list). So the browser can send the
/// natural `{"title":"Hi","index":5}` shape without a custom request type.
internal enum WebRequests {
  /// One sort descriptor: a field name plus a direction. Field names follow
  /// CloudKit Web Services / CloudKit JS naming — including the implicit
  /// system fields `___createTime` and `___modTime`, which must be marked
  /// SORTABLE in the schema.
  internal struct QuerySortField: Decodable, Sendable {
    /// CloudKit Web Services field name. Note: CloudKit JS's
    /// `performQuery({ sortBy })` uses `fieldName` for the same concept —
    /// the browser-side code maps this property to `fieldName` when issuing
    /// CloudKit-JS-mode queries (see `queryNotes` in `index.html`).
    internal let field: String
    internal let ascending: Bool
  }

  /// `POST /api/records/query`
  internal struct Query: Decodable {
    private enum CodingKeys: String, CodingKey {
      case recordType
      case limit
      case sortBy
      case database
    }

    internal let recordType: String
    internal let limit: Int?
    internal let sortBy: [QuerySortField]?
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.recordType = try container.decode(String.self, forKey: .recordType)
      self.limit = try container.decodeIfPresent(Int.self, forKey: .limit)
      self.sortBy = try container.decodeIfPresent(
        [QuerySortField].self, forKey: .sortBy
      )
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/records/create`
  internal struct Create: Decodable {
    private enum CodingKeys: String, CodingKey {
      case recordType
      case fields
      case database
    }

    internal let recordType: String
    internal let fields: [String: FieldValue]
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.recordType = try container.decode(String.self, forKey: .recordType)
      self.fields = try container.decode(
        [String: FieldValue].self, forKey: .fields
      )
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/records/update`
  ///
  /// `recordChangeTag` carries the optimistic-locking token CloudKit returns
  /// on every record. The browser already holds it from the last query, so
  /// it forwards directly to MistKit without a server-side fetch round-trip.
  internal struct Update: Decodable {
    private enum CodingKeys: String, CodingKey {
      case recordType
      case recordName
      case fields
      case recordChangeTag
      case database
    }

    internal let recordType: String
    internal let recordName: String
    internal let fields: [String: FieldValue]
    internal let recordChangeTag: String?
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.recordType = try container.decode(String.self, forKey: .recordType)
      self.recordName = try container.decode(String.self, forKey: .recordName)
      self.fields = try container.decode(
        [String: FieldValue].self, forKey: .fields
      )
      self.recordChangeTag = try container.decodeIfPresent(
        String.self, forKey: .recordChangeTag
      )
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

  /// `POST /api/records/delete`
  ///
  /// `recordChangeTag` is required by CloudKit Web Services to delete an
  /// existing record. Omitting it produces `BadRequestException: missing
  /// required field 'recordChangeTag'`.
  internal struct Delete: Decodable {
    private enum CodingKeys: String, CodingKey {
      case recordType
      case recordName
      case recordChangeTag
      case database
    }

    internal let recordType: String
    internal let recordName: String
    internal let recordChangeTag: String?
    internal let database: MistKit.Database

    internal init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.recordType = try container.decode(String.self, forKey: .recordType)
      self.recordName = try container.decode(String.self, forKey: .recordName)
      self.recordChangeTag = try container.decodeIfPresent(
        String.self, forKey: .recordChangeTag
      )
      self.database = try WebRequests.decodeDatabase(
        from: container, forKey: .database
      )
    }
  }

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

  /// CloudKit database targeted by a request. Defaults to `.private` when
  /// the field is omitted so legacy clients (pre-database-picker) keep
  /// working.
  internal static let defaultDatabase: MistKit.Database = .private

  /// Decode `database` (string raw-value) from a keyed container. Falls back
  /// to `defaultDatabase` when the key is absent and throws when present but
  /// unrecognized so a typo surfaces as a `400` rather than a silent default.
  fileprivate static func decodeDatabase<Key: CodingKey>(
    from container: KeyedDecodingContainer<Key>,
    forKey key: Key
  ) throws -> MistKit.Database {
    guard let raw = try container.decodeIfPresent(String.self, forKey: key)
    else {
      return defaultDatabase
    }
    guard let database = MistDemoConfig.parseDatabase(raw) else {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription:
          "Unrecognized database '\(raw)' — expected one of: public, private, shared"
      )
    }
    return database
  }
}
