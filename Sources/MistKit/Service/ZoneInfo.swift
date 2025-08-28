//
//  ZoneInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

/// Zone information from CloudKit
public struct ZoneInfo: Encodable {
  /// The zone name
  public let zoneName: String
  /// The owner record name
  public let ownerRecordName: String?
  /// The zone capabilities
  public let capabilities: [String]

  /// Initialize zone information
  public init(zoneName: String, ownerRecordName: String?, capabilities: [String]) {
    self.zoneName = zoneName
    self.ownerRecordName = ownerRecordName
    self.capabilities = capabilities
  }
}
