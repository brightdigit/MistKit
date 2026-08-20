//
//  ZoneChangesRequest.swift
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

// swiftlint:disable line_length - DocC symbol links cannot be wrapped
/// A per-zone entry in a `changes/zone` request.
///
/// Identifies the zone to fetch record changes from and, optionally, overrides
/// the request-level tuning values for that zone. Values left `nil` here fall
/// back to whatever the enclosing
/// ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)``
/// call specified.
public struct ZoneChangesRequest: Sendable {
  // swiftlint:enable line_length
  /// The zone to fetch record changes from.
  public let zoneID: ZoneID
  /// Token from a previous fetch of this zone (`nil` = initial fetch).
  public let syncToken: String?
  /// Whether this zone's changes are returned in reverse order.
  public let reverse: Bool?
  /// Field names limiting the fields returned per changed record in this zone.
  public let desiredKeys: [String]?
  /// Maximum number of records to fetch for this zone.
  public let resultsLimit: Int?
  /// Record-type names limiting this zone's change feed.
  public let desiredRecordTypes: [String]?

  /// Creates a per-zone change request.
  ///
  /// - Parameters:
  ///   - zoneID: The zone to fetch record changes from.
  ///   - syncToken: Token from a previous fetch of this zone.
  ///   - reverse: Whether changes are returned in reverse order.
  ///   - desiredKeys: Field names limiting the fields returned per record.
  ///   - resultsLimit: Maximum number of records to fetch for this zone.
  ///   - desiredRecordTypes: Record-type names limiting this zone's feed.
  public init(
    zoneID: ZoneID,
    syncToken: String? = nil,
    reverse: Bool? = nil,
    desiredKeys: [String]? = nil,
    resultsLimit: Int? = nil,
    desiredRecordTypes: [String]? = nil
  ) {
    self.zoneID = zoneID
    self.syncToken = syncToken
    self.reverse = reverse
    self.desiredKeys = desiredKeys
    self.resultsLimit = resultsLimit
    self.desiredRecordTypes = desiredRecordTypes
  }
}

extension Components.Schemas.RecordZoneChangesRequestZone {
  /// Converts a domain per-zone change request into its wire representation.
  internal init(from request: ZoneChangesRequest) {
    self.init(
      zoneID: Components.Schemas.ZoneID(from: request.zoneID),
      syncToken: request.syncToken,
      reverse: request.reverse,
      desiredKeys: request.desiredKeys,
      resultsLimit: request.resultsLimit,
      desiredRecordTypes: request.desiredRecordTypes
    )
  }
}
