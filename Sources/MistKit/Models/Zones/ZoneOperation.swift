//
//  ZoneOperation.swift
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

/// A create-or-delete operation against a CloudKit zone, used by
/// `CloudKitService.modifyZones(_:database:)`.
internal import MistKitOpenAPI

public enum ZoneOperation: Sendable, Equatable, Hashable {
  /// Create the given zone.
  case create(ZoneID)

  /// Delete the given zone.
  case delete(ZoneID)

  /// The zone identifier that this operation targets.
  public var zoneID: ZoneID {
    switch self {
    case .create(let zoneID), .delete(let zoneID):
      return zoneID
    }
  }
}

// MARK: - Internal Conversion
extension Components.Schemas.ZoneOperation {
  internal init(from operation: ZoneOperation) {
    let operationType: Components.Schemas.ZoneOperation.operationTypePayload
    switch operation {
    case .create:
      operationType = .create
    case .delete:
      operationType = .delete
    }
    self.init(
      operationType: operationType,
      zone: .init(zoneID: Components.Schemas.ZoneID(from: operation.zoneID))
    )
  }
}
