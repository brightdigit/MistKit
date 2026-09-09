//
//  ZoneType.swift
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

/// The zone's type as reported on the CloudKit Web Services wire.
///
/// Live responses use exactly two values: the database default zone
/// (``defaultZone``) and every other zone (``regularCustom``). The key is
/// optional — callers may omit it on requests.
public enum ZoneType: String, Codable, Sendable, Equatable, Hashable, CaseIterable {
  /// `_defaultZone` in public or private databases.
  case defaultZone = "DEFAULT_ZONE"
  /// User-created custom zones, Core Data mirroring zones, and shared-database zones.
  case regularCustom = "REGULAR_CUSTOM_ZONE"
}

// MARK: - Internal Conversion
extension ZoneType {
  /// Maps an optional wire string to a domain value.
  ///
  /// `nil` stays `nil`. Any other unrecognized string throws
  /// ``ConversionError/unrecognizedZoneType(_:)``.
  internal static func fromWire(_ wire: String?) throws(ConversionError) -> ZoneType? {
    guard let wire else {
      return nil
    }
    guard let value = ZoneType(rawValue: wire) else {
      throw ConversionError.unrecognizedZoneType(wire)
    }
    return value
  }
}
