//
// CloudKitUserFetchResponse.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct CloudKitUserFetchResponse: Codable {
  public let userRecordName: UUID

  public init(userRecordName: UUID) {
    self.userRecordName = userRecordName
  }

  enum CodingKeys: CodingKey {
    case userRecordName
  }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    let userRecordNameString = try values.decode(String.self, forKey: .userRecordName)
    guard let userRecordName = RecordNameParser.uuid(fromRecordName: userRecordNameString) else {
      throw DecodingError.dataCorruptedError(forKey: .userRecordName, in: values, debugDescription: "Invalid UUID")
    }
    self.userRecordName = userRecordName
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    let uuidString = userRecordName.uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    try container.encode("_\(uuidString)", forKey: .userRecordName)
  }
}
