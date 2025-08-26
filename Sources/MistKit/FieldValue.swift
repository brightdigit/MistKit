//
//  FieldValue.swift
//  MistKit
//
//  Created by Leo Dion on 7/9/25.
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
    public let latitude: Double
    public let longitude: Double
    public let horizontalAccuracy: Double?
    public let verticalAccuracy: Double?
    public let altitude: Double?
    public let speed: Double?
    public let course: Double?
    public let timestamp: Date?

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
    public let recordName: String
    public let action: String?  // "DELETE_SELF" or nil

    public init(recordName: String, action: String? = nil) {
      self.recordName = recordName
      self.action = action
    }
  }

  /// Asset dictionary as defined in CloudKit Web Services
  public struct Asset: Codable, Equatable {
    public let fileChecksum: String?
    public let size: Int64?
    public let referenceChecksum: String?
    public let wrappingKey: String?
    public let receipt: String?
    public let downloadURL: String?

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
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let value):
      try container.encode(value)
    case .int64(let value):
      try container.encode(value)
    case .double(let value):
      try container.encode(value)
    case .boolean(let value):
      try container.encode(value)
    case .bytes(let value):
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

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    // Try to decode in order of most specific to least specific
    if let value = try? container.decode(String.self) {
      self = .string(value)
      return
    }
    if let value = try? container.decode(Int64.self) {
      self = .int64(value)
      return
    }
    if let value = try? container.decode(Double.self) {
      self = .double(value)
      return
    }
    if let value = try? container.decode(Bool.self) {
      self = .boolean(value)
      return
    }
    if let value = try? container.decode([FieldValue].self) {
      self = .list(value)
      return
    }
    if let value = try? container.decode(Location.self) {
      self = .location(value)
      return
    }
    if let value = try? container.decode(Reference.self) {
      self = .reference(value)
      return
    }
    if let value = try? container.decode(Asset.self) {
      self = .asset(value)
      return
    }
    // Try to decode as date (milliseconds since epoch)
    if let value = try? container.decode(Double.self) {
      self = .date(Date(timeIntervalSince1970: value / 1_000))
      return
    }
    throw DecodingError.dataCorruptedError(
      in: container, debugDescription: "Unable to decode FieldValue")
  }
}
