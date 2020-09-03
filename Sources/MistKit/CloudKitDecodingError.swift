//
// CloudKitDecodingError.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

public enum CloudKitDecodingError: Error {
  case missingKey(String)
  case invalidData(String)
}
