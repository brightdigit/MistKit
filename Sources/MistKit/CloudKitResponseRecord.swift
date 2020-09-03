//
// CloudKitResponseRecord.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct CloudKitResponseRecord: Codable {
  public let recordType: String
  public let recordName: UUID
  public let fields: [String: CloudKitField]
}

public extension CloudKitResponseRecord {
  func uuid(fromKey key: String) throws -> UUID {
    let value = try string(fromKey: key)

    guard let uuid = Data(base64Encoded: value).flatMap(UUID.init(data:)) else {
      throw CloudKitDecodingError.invalidData(value)
    }

    return uuid
  }

  func string(fromKey key: String) throws -> String {
    guard let field = fields[key] else {
      throw CloudKitDecodingError.missingKey(key)
    }

    return field.value
  }

  func integer(fromKey key: String) throws -> Int {
    let value = try string(fromKey: key)

    guard let integer = Int(value) else {
      throw CloudKitDecodingError.invalidData(value)
    }

    return integer
  }
}
