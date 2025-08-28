//
//  FieldValue.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import Foundation

/// Represents a CloudKit field value as defined in the CloudKit Web Services API
public enum FieldValue: Codable, Equatable {
  case string(String)
  case int64(Int64)
  case double(Double)
  case boolean(Bool)
  case bytes(String)  // Base64-encoded string
  case date(Date)  // Date/time value
  case location(Location)
  case reference(Reference)
  case asset(Asset)
  case list([FieldValue])

  /// Location dictionary as defined in CloudKit Web Services
  public struct Location: Codable, Equatable {
    /// The latitude coordinate
    public let latitude: Double
    /// The longitude coordinate
    public let longitude: Double
    /// The horizontal accuracy in meters
    public let horizontalAccuracy: Double?
    /// The vertical accuracy in meters
    public let verticalAccuracy: Double?
    /// The altitude in meters
    public let altitude: Double?
    /// The speed in meters per second
    public let speed: Double?
    /// The course in degrees
    public let course: Double?
    /// The timestamp when location was recorded
    public let timestamp: Date?

    /// Initialize a location value
    public init(
      latitude: Double,
      longitude: Double,
      horizontalAccuracy: Double? = nil,
      verticalAccuracy: Double? = nil,
      altitude: Double? = nil,
      speed: Double? = nil,
      course: Double? = nil,
      timestamp: Date? = nil
    ) {
      self.latitude = latitude
      self.longitude = longitude
      self.horizontalAccuracy = horizontalAccuracy
      self.verticalAccuracy = verticalAccuracy
      self.altitude = altitude
      self.speed = speed
      self.course = course
      self.timestamp = timestamp
    }
  }

  /// Reference dictionary as defined in CloudKit Web Services
  public struct Reference: Codable, Equatable {
    /// The record name being referenced
    public let recordName: String
    /// The action to take ("DELETE_SELF" or nil)
    public let action: String?

    /// Initialize a reference value
    public init(recordName: String, action: String? = nil) {
      self.recordName = recordName
      self.action = action
    }
  }

  /// Asset dictionary as defined in CloudKit Web Services
  public struct Asset: Codable, Equatable {
    /// The file checksum
    public let fileChecksum: String?
    /// The file size in bytes
    public let size: Int64?
    /// The reference checksum
    public let referenceChecksum: String?
    /// The wrapping key for encryption
    public let wrappingKey: String?
    /// The upload receipt
    public let receipt: String?
    /// The download URL
    public let downloadURL: String?

    /// Initialize an asset value
    public init(
      fileChecksum: String? = nil,
      size: Int64? = nil,
      referenceChecksum: String? = nil,
      wrappingKey: String? = nil,
      receipt: String? = nil,
      downloadURL: String? = nil
    ) {
      self.fileChecksum = fileChecksum
      self.size = size
      self.referenceChecksum = referenceChecksum
      self.wrappingKey = wrappingKey
      self.receipt = receipt
      self.downloadURL = downloadURL
    }
  }

  // MARK: - Codable
  /// Initialize field value from decoder
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try Self.decodeBasicTypes(from: container) {
      self = value
      return
    }

    if let value = try Self.decodeComplexTypes(from: container) {
      self = value
      return
    }

    throw DecodingError.dataCorruptedError(
      in: container,
      debugDescription: "Unable to decode FieldValue"
    )
  }

  /// Decode basic field value types (string, int64, double, boolean)
  private static func decodeBasicTypes(from container: SingleValueDecodingContainer) throws
    -> FieldValue?
  {
    if let value = try? container.decode(String.self) {
      return .string(value)
    }
    if let value = try? container.decode(Int64.self) {
      return .int64(value)
    }
    if let value = try? container.decode(Double.self) {
      return .double(value)
    }
    if let value = try? container.decode(Bool.self) {
      return .boolean(value)
    }
    return nil
  }

  /// Decode complex field value types (list, location, reference, asset, date)
  private static func decodeComplexTypes(from container: SingleValueDecodingContainer) throws
    -> FieldValue?
  {
    if let value = try? container.decode([FieldValue].self) {
      return .list(value)
    }
    if let value = try? container.decode(Location.self) {
      return .location(value)
    }
    if let value = try? container.decode(Reference.self) {
      return .reference(value)
    }
    if let value = try? container.decode(Asset.self) {
      return .asset(value)
    }
    // Try to decode as date (milliseconds since epoch)
    if let value = try? container.decode(Double.self) {
      return .date(Date(timeIntervalSince1970: value / 1_000))
    }
    return nil
  }

  /// Encode field value to encoder
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .string(let value), .bytes(let value):
      try container.encode(value)
    case .int64(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .boolean(let value):
      try container.encode(value)
    case .date(let value):
      try container.encode(value.timeIntervalSince1970 * 1_000)
    case .location(let value):
      try container.encode(value)
    case .reference(let value):
      try container.encode(value)
    case .asset(let value):
      try container.encode(value)
    case .list(let values):
      try container.encode(values)
    }
  }
}
