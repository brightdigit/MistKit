//
// CloudKitQuery.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct CloudKitQuery: Codable {
  public let recordType: String

  public init(recordType: String) {
    self.recordType = recordType
  }
}
