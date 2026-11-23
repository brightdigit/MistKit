internal import Foundation

@testable import MistKit

/// A tabletop-games schema for the query validation tests.
internal enum QueryFixtures {
  internal static let tabletop = CloudKitSchema(recordTypes: [player, match])

  internal static let player = SchemaRecordType(
    name: "Player",
    fields: systemFields + [
      field("avatar", .asset),
      field("country", .string),
      field("displayName", .string, queryable: true, sortable: true, searchable: true),
      field("gamesPlayed", .int64, sortable: true),
      field("handle", .string, queryable: true),
      field("lastSeen", .timestamp, queryable: true, sortable: true),
      field("rating", .int64, queryable: true, sortable: true),
      field("secret", SchemaFieldType(.string, isEncrypted: true)),
      field("settings", .string),
      field("tags", SchemaFieldType(.string, isList: true), queryable: true),
      field("weight", .number(preferredAs: nil), queryable: true),
    ]
  )

  internal static let match = SchemaRecordType(
    name: "Match",
    fields: systemFields + [
      field("durationSeconds", .int64, queryable: true, sortable: true),
      field("players", SchemaFieldType(.reference, isList: true), queryable: true),
      field("score", .string),
      field("startedAt", .timestamp, queryable: true, sortable: true),
      field("venue", .location, queryable: true),
      field("winner", .reference, queryable: true),
    ]
  )

  /// The system fields as an exported schema declares them, with
  /// `___recordID` `QUERYABLE`.
  internal static let systemFields: [SchemaField] = [
    field("___createTime", .timestamp, sortable: true),
    field("___modTime", .timestamp, queryable: true, sortable: true),
    field("___recordID", .reference, queryable: true),
  ]

  internal static func field(
    _ name: String,
    _ primitive: SchemaPrimitiveType,
    queryable: Bool = false,
    sortable: Bool = false,
    searchable: Bool = false
  ) -> SchemaField {
    field(
      name,
      SchemaFieldType(primitive),
      queryable: queryable,
      sortable: sortable,
      searchable: searchable
    )
  }

  internal static func field(
    _ name: String,
    _ type: SchemaFieldType,
    queryable: Bool = false,
    sortable: Bool = false,
    searchable: Bool = false
  ) -> SchemaField {
    SchemaField(
      name: name,
      type: type,
      isQueryable: queryable,
      isSortable: sortable,
      isSearchable: searchable
    )
  }
}
