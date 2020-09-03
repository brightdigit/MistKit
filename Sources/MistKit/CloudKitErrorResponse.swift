//
// CloudKitErrorResponse.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct CloudKitErrorResponse: Codable {
  public let uuid: UUID
  public let serverErrorCode: CloudKitErrorCode
  public let reason: String
  public let redirectURL: URL
}
