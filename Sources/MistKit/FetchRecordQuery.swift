//
// CloudKitQueryRequest.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation


public struct FetchRecordQuery<QueryType : MKQueryProtocol>: MKEncodable {
  public let query: QueryType
  public let desiredKeys: [String]?
  public let numbersAsStrings: Bool = true

  public init(query: QueryType) {
    self.query = query
    self.desiredKeys = query.desiredKeys
  }
}
