//
// UUID.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public extension UUID {
  internal init(data: Data) {
    var bytes = [UInt8](repeating: 0, count: data.count)
    _ = bytes.withUnsafeMutableBufferPointer {
      data.copyBytes(to: $0)
    }
    self = NSUUID(uuidBytes: bytes) as UUID
  }

  var data: NSData {
    let bytes = Array(uuid: self)
    return Data(bytes) as NSData
  }
}
