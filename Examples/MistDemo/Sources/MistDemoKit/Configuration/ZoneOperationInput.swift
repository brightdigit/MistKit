//
//  ZoneOperationInput.swift
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

public import Foundation
public import MistKit

/// One zone operation parsed from the modify-zones JSON payload.
public struct ZoneOperationInput: Codable, Sendable, Equatable {
  /// The operation kind ("create" or "delete").
  public let type: String
  /// The CloudKit zone name.
  public let zoneName: String

  /// Creates a new instance.
  public init(type: String, zoneName: String) {
    self.type = type
    self.zoneName = zoneName
  }

  /// Convert this operation input into a MistKit `ZoneOperation`.
  ///
  /// - Throws: `ModifyZonesError.invalidOperationType` for unknown `type`
  ///   values, or `.invalidZoneName` for empty / whitespace-only names.
  public func toZoneOperation() throws -> ZoneOperation {
    let trimmed = zoneName.trimmingCharacters(in: .whitespaces)
    guard !trimmed.isEmpty else {
      throw ModifyZonesError.invalidZoneName(zoneName)
    }
    let zoneID = ZoneID(zoneName: trimmed, ownerName: nil)

    switch type.lowercased() {
    case "create":
      return .create(zoneID)
    case "delete":
      return .delete(zoneID)
    default:
      throw ModifyZonesError.invalidOperationType(type)
    }
  }
}
