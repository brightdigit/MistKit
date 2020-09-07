//
// CloudKitQueryRequest.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct CloudKitQueryRequest: Codable {
  public let query: CloudKitQuery
  public let desiredKeys: [String]?
  public let numbersAsStrings: Bool = true

  public init(query: CloudKitQuery, desiredKeys: [String]? = nil) {
    self.query = query
    self.desiredKeys = desiredKeys
  }
}
