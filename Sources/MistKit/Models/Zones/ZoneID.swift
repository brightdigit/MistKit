//
//  ZoneID.swift
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

internal import Foundation
internal import MistKitOpenAPI

/// Identifies a specific CloudKit zone
///
/// Zone IDs uniquely identify a record zone within a database.
/// The _defaultZone is automatically available in all databases.
public struct ZoneID: Codable, Sendable, Equatable, Hashable {
  /// The default zone present in all databases
  public static let defaultZone = ZoneID(zoneName: "_defaultZone", ownerName: nil)

  /// The zone name (e.g., "_defaultZone", "Articles")
  public let zoneName: String
  /// The owner's record name (optional, nil for current user)
  public let ownerName: String?
  /// The zone's type.
  ///
  /// `nil` when the server omits the key.
  public let zoneType: ZoneType?

  /// Whether this names ``defaultZone``.
  ///
  /// Matched by name only: CloudKit reports every zone with its owner, the
  /// signed-in user's default zone included.
  public var isDefaultZone: Bool {
    zoneName == Self.defaultZone.zoneName
  }

  /// The zone's identity: its name and owner, without ``zoneType``.
  ///
  /// A zone CloudKit reports carries its type, while one built from a name
  /// (or read from a reference) doesn't, so compare identities rather than
  /// zone IDs when either may have come from the server.
  public var identity: ZoneID {
    ZoneID(zoneName: zoneName, ownerName: ownerName)
  }

  /// The zone to name in a request: `nil` for the default zone, which
  /// CloudKit assumes when a request names none.
  public var requestZone: ZoneID? {
    isDefaultZone ? nil : self
  }

  /// The zone as a client keeps it: ``defaultZone`` for the default zone,
  /// whoever CloudKit says owns it, and ``identity`` otherwise.
  public var normalized: ZoneID {
    isDefaultZone ? Self.defaultZone : identity
  }

  /// Initialize a zone identifier
  /// - Parameters:
  ///   - zoneName: The zone name
  ///   - ownerName: Optional owner record name (nil = current user)
  ///   - zoneType: Optional zone type from the wire payload
  public init(zoneName: String, ownerName: String? = nil, zoneType: ZoneType? = nil) {
    self.zoneName = zoneName
    self.ownerName = ownerName
    self.zoneType = zoneType
  }

  /// A reference's zone from the wire schema: name and owner only, since a
  /// reference never carries a zone type.
  internal init(referenceZone schema: Components.Schemas.ZoneID) {
    self.init(
      zoneName: schema.zoneName ?? ZoneID.defaultZone.zoneName,
      ownerName: schema.ownerRecordName
    )
  }

  /// Lift a zone identifier from the wire schema.
  ///
  /// A missing `zoneName` falls back to ``defaultZone``'s name — share
  /// results may omit it when CloudKit only returns an owner.
  internal init(from schema: Components.Schemas.ZoneID) throws(ConversionError) {
    self.init(
      zoneName: schema.zoneName ?? ZoneID.defaultZone.zoneName,
      ownerName: schema.ownerRecordName,
      zoneType: try ZoneType.fromWire(schema.zoneType)
    )
  }
}

// MARK: - Internal Conversion
extension Components.Schemas.ZoneID {
  internal init(from zoneID: ZoneID) {
    self.init(
      zoneName: zoneID.zoneName,
      ownerRecordName: zoneID.ownerName,
      zoneType: zoneID.zoneType?.rawValue
    )
  }
}
