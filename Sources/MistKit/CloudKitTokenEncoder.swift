//
// CloudKitTokenEncoder.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

public protocol CloudKitTokenEncoder {
  func encode(_ token: String) -> String
}
