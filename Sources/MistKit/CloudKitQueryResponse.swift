//
// CloudKitQueryResponse.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct CloudKitQueryResponse: Codable {
  public let records: [CloudKitResponseRecord]
}
