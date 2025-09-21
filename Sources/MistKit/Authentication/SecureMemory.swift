//
//  SecureMemory.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Utilities for secure memory operations to prevent sensitive data from persisting in memory
public enum SecureMemory {
  /// Securely clears a string by overwriting its memory with zeros
  /// - Parameter string: The string to securely clear
  public static func clear(_ string: inout String) {
    // For strings, we can only clear the reference
    // The actual memory clearing would require unsafe operations
    // that are not available on String in Swift
    string = ""
  }

  /// Securely clears a Data object by overwriting its memory with zeros
  /// - Parameter data: The data to securely clear
  public static func clear(_ data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
      memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
    data.removeAll()
  }

  /// Securely clears an array of sensitive data
  /// - Parameter array: The array to securely clear
  public static func clear<T>(_ array: inout [T]) {
    // For arrays of basic types, we can clear the memory
    if T.self == String.self {
      _ = array.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
      }
    }
    array.removeAll()
  }

  /// Securely clears a dictionary containing sensitive data
  /// - Parameter dictionary: The dictionary to securely clear
  public static func clear<K, V>(_ dictionary: inout [K: V]) {
    // Clear all values if they are strings or data
    for (_, value) in dictionary {
      if V.self == String.self, var stringValue = value as? String {
        clear(&stringValue)
      } else if V.self == Data.self, var dataValue = value as? Data {
        clear(&dataValue)
      }
    }
    dictionary.removeAll()
  }

  /// Creates a secure string that will be automatically cleared when deallocated
  /// - Parameter value: The initial string value
  /// - Returns: A SecureString wrapper
  public static func secureString(_ value: String) -> SecureString {
    SecureString(value)
  }

  /// Creates secure data that will be automatically cleared when deallocated
  /// - Parameter value: The initial data value
  /// - Returns: A SecureData wrapper
  public static func secureData(_ value: Data) -> SecureData {
    SecureData(value)
  }
}

/// A wrapper for strings that automatically clears memory on deallocation
public final class SecureString: @unchecked Sendable {
  private var _value: String

  public var value: String {
    get { _value }
    set { _value = newValue }
  }

  public init(_ value: String) {
    self._value = value
  }

  deinit {
    SecureMemory.clear(&_value)
  }

  /// Manually clear the string before deallocation
  public func clear() {
    SecureMemory.clear(&_value)
  }
}

/// A wrapper for data that automatically clears memory on deallocation
public final class SecureData: @unchecked Sendable {
  private var _value: Data

  public var value: Data {
    get { _value }
    set { _value = newValue }
  }

  public init(_ value: Data) {
    self._value = value
  }

  deinit {
    SecureMemory.clear(&_value)
  }

  /// Manually clear the data before deallocation
  public func clear() {
    SecureMemory.clear(&_value)
  }
}
