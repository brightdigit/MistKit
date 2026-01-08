//
//  SignedStatus.swift
//  BushelCloud
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

import Foundation

/// Represents the signing status for a build
/// Can be: array of device IDs, boolean true (all signed), or empty array (none signed)
internal enum SignedStatus: Codable {
  case devices([String])  // Array of signed device IDs
  case all(Bool)  // true = all devices signed
  case none  // Empty array = not signed

  internal init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    // Try decoding as array first
    if let devices = try? container.decode([String].self) {
      if devices.isEmpty {
        self = .none
      } else {
        self = .devices(devices)
      }
    }
    // Then try boolean
    else if let allSigned = try? container.decode(Bool.self) {
      self = .all(allSigned)
    }
    // Default to none if decoding fails
    else {
      self = .none
    }
  }

  internal func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .devices(let devices):
      try container.encode(devices)
    case .all(let value):
      try container.encode(value)
    case .none:
      try container.encode([String]())
    }
  }

  /// Check if a specific device identifier is signed
  internal func isSigned(for deviceIdentifier: String) -> Bool {
    switch self {
    case .devices(let devices):
      return devices.contains(deviceIdentifier)
    case .all(true):
      return true
    case .all(false), .none:
      return false
    }
  }
}
