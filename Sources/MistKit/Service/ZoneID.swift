//
//  ZoneID.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Identifies a specific CloudKit zone
///
/// Zone IDs uniquely identify a record zone within a database.
/// The _defaultZone is automatically available in all databases.
public struct ZoneID: Sendable, Equatable, Hashable {
  /// The zone name (e.g., "_defaultZone", "Articles")
  public let zoneName: String
  /// The owner's record name (optional, nil for current user)
  public let ownerName: String?

  /// Initialize a zone identifier
  /// - Parameters:
  ///   - zoneName: The zone name
  ///   - ownerName: Optional owner record name (nil = current user)
  public init(zoneName: String, ownerName: String? = nil) {
    self.zoneName = zoneName
    self.ownerName = ownerName
  }

  /// The default zone present in all databases
  public static let defaultZone = ZoneID(zoneName: "_defaultZone", ownerName: nil)
}

// MARK: - Internal Conversion
extension Components.Schemas.ZoneID {
  internal init(from zoneID: ZoneID) {
    self.init(
      zoneName: zoneID.zoneName,
      ownerName: zoneID.ownerName
    )
  }
}
