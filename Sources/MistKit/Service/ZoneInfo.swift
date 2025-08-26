//
//  ZoneInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

public struct ZoneInfo: Encodable {
  public let zoneName: String
  public let ownerRecordName: String?
  public let capabilities: [String]

  public init(zoneName: String, ownerRecordName: String?, capabilities: [String]) {
    self.zoneName = zoneName
    self.ownerRecordName = ownerRecordName
    self.capabilities = capabilities
  }
}
