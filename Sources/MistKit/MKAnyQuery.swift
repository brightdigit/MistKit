//
// CloudKitQuery.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public protocol MKQueryProtocol : Encodable {
  var recordType : String { get }
  var desiredKeys : [String]? { get }
}

public protocol MKQueryRecord {
  static var recordType : String { get }
  static var desiredKeys : [String]? { get }
  
  var recordName : UUID { get }
  init (record: CloudKitResponseRecord) throws
}


public struct TodoListItem : MKQueryRecord {
  public init(record: CloudKitResponseRecord) throws {
    self.recordName = record.recordName
    self.title = try record.string(fromKey: "title")
  }
  
  public static var recordType: String = "TodoItem"
  public static var desiredKeys: [String]? = ["title"]
  
  public let recordName : UUID
  public let title : String
}

public struct MKQuery<RecordType : MKQueryRecord> : MKQueryProtocol {
  public let recordType : String
  public let desiredKeys: [String]?
  
  enum CodingKeys : String, CodingKey {
    case recordType
  }
  
  public init(recordType: RecordType.Type) {
    self.recordType = recordType.recordType
    self.desiredKeys = recordType.desiredKeys
  }
}

public struct MKAnyQuery: MKQueryProtocol {
  public let recordType: String
  public let desiredKeys: [String]?
  
  enum CodingKeys : String, CodingKey {
    case recordType
  }

  public init(recordType: String, desiredKeys : [String]? = nil) {
    self.recordType = recordType
    self.desiredKeys = desiredKeys
  }
}
