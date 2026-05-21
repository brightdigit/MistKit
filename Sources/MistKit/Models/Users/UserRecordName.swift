//
//  UserRecordName.swift
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

/// The record-name slot of a ``UserIdentity``.
///
/// CloudKit's discover endpoints return an identity's record name only when the
/// user is discoverable; a non-discoverable user comes back with `lookupInfo`
/// alone and no record name. Modeling that as an enum (rather than an optional
/// `String`) makes the two states explicit instead of overloading `nil`.
public enum UserRecordName: Codable, Sendable, Hashable {
  /// The user is discoverable; the associated value is their record name in the
  /// Users zone.
  case recordName(String)
  /// The user is not discoverable, so CloudKit returned no record name.
  case nonDiscoverable

  /// Maps CloudKit's optional record-name string onto the two-state enum: a
  /// present value is ``recordName(_:)``, a missing one is ``nonDiscoverable``.
  internal init(_ recordName: String?) {
    self = recordName.map(Self.recordName) ?? .nonDiscoverable
  }

  /// Decodes a record name from a single string value, treating `null` as
  /// ``nonDiscoverable`` so the JSON shape stays a plain optional string.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      self = .nonDiscoverable
    } else {
      self = .recordName(try container.decode(String.self))
    }
  }

  /// Encodes a record name as a string, or `null` when non-discoverable.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .recordName(let name): try container.encode(name)
    case .nonDiscoverable: try container.encodeNil()
    }
  }
}
