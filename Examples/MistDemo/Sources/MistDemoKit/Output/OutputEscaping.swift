//
//  OutputEscaping.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// Utilities for escaping strings in various output formats
/// - Warning: Deprecated. Use protocol-based escapers (CSVEscaper, YAMLEscaper, JSONEscaper) instead.
@available(
  *, deprecated,
  message: "Use protocol-based escapers (CSVEscaper, YAMLEscaper, JSONEscaper) instead"
)
public enum OutputEscaping {
  // MARK: - CSV Escaping

  /// Escape a string for CSV output according to RFC 4180
  /// - Parameter string: The string to escape
  /// - Returns: The escaped string suitable for CSV output
  /// - Warning: Deprecated. Use CSVEscaper instead.
  @available(*, deprecated, message: "Use CSVEscaper().escape(_:) instead")
  public static func csvEscape(_ string: String) -> String {
    // Check if escaping is needed
    let needsEscaping = string.contains { character in
      switch character {
      case ",", "\"", "\n", "\r", "\t":
        return true
      default:
        return false
      }
    }

    // If no special characters, return as-is
    guard needsEscaping else {
      return string
    }

    // Escape quotes by doubling them and wrap in quotes
    let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
    return "\"\(escaped)\""
  }

  // MARK: - YAML Escaping

  /// Escape a string for YAML output
  /// - Parameter string: The string to escape
  /// - Returns: The escaped string suitable for YAML output
  /// - Warning: Deprecated. Use YAMLEscaper instead.
  @available(*, deprecated, message: "Use YAMLEscaper().escape(_:) instead")
  public static func yamlEscape(_ string: String) -> String {
    // Check if the string needs escaping
    let needsEscaping = yamlNeedsEscaping(string)

    // If no escaping needed, return as-is
    guard needsEscaping else {
      return string
    }

    // For multi-line strings, use literal block scalar
    if string.contains("\n") {
      return yamlBlockScalar(string)
    }

    // For single-line strings with special characters, use double quotes
    let escaped =
      string
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\t", with: "\\t")
      .replacingOccurrences(of: "\r", with: "\\r")

    return "\"\(escaped)\""
  }

  // MARK: - Private Helpers

  /// Check if a string needs YAML escaping
  private static func yamlNeedsEscaping(_ string: String) -> Bool {
    // Empty strings need quotes
    if string.isEmpty {
      return true
    }

    if yamlNeedsEscapingByBoundary(string) {
      return true
    }

    return yamlNeedsEscapingByContent(string)
  }

  /// Check boundary characters and reserved YAML patterns.
  private static func yamlNeedsEscapingByBoundary(
    _ string: String
  ) -> Bool {
    let specialChars: Set<Character> = [
      ":", "#", "@", "`", "|", ">", "'", "\"",
      "[", "]", "{", "}", ",", "&", "*", "!",
      "%", "\\", "?", "-", "<", "=", "~",
    ]

    if let first = string.first {
      if specialChars.contains(first) || first.isWhitespace {
        return true
      }
    }

    if let last = string.last, last.isWhitespace {
      return true
    }

    let specialPatterns = [
      "yes", "no", "true", "false", "on", "off",
      "null", "~", "YES", "NO", "TRUE", "FALSE",
      "ON", "OFF", "NULL", "Yes", "No", "True",
      "False", "On", "Off", "Null",
    ]

    return specialPatterns.contains(string)
  }

  /// Check interior characters and numeric patterns.
  private static func yamlNeedsEscapingByContent(
    _ string: String
  ) -> Bool {
    let specialChars: Set<Character> = [
      ":", "#", "@", "`", "|", ">", "'", "\"",
      "[", "]", "{", "}", ",", "&", "*", "!",
      "%", "\\", "?", "-", "<", "=", "~",
    ]

    if Double(string) != nil || Int(string) != nil {
      return true
    }

    for char in string
    where specialChars.contains(char)
      || char == "\n" || char == "\r" || char == "\t"
    {
      return true
    }

    return false
  }

  /// Create a YAML block scalar for multi-line strings
  private static func yamlBlockScalar(_ string: String) -> String {
    // Use literal block scalar (|) for multi-line strings
    // This preserves line breaks and doesn't require escaping
    let lines = string.split(separator: "\n", omittingEmptySubsequences: false)

    // Check if we need folded scalar (>) or literal scalar (|)
    // Use literal scalar to preserve formatting
    var result = "|\n"

    // Indent each line with 2 spaces
    for line in lines {
      if line.isEmpty {
        result += "\n"
      } else {
        result += "    \(line)\n"
      }
    }

    // Remove trailing newline if original didn't have one
    if !string.hasSuffix("\n") && result.hasSuffix("\n") {
      result.removeLast()
    }

    return result
  }

  // MARK: - JSON Escaping

  /// Escape a string for JSON output (usually handled by JSONEncoder, but useful for manual JSON building)
  /// - Parameter string: The string to escape
  /// - Returns: The escaped string suitable for JSON output
  /// - Warning: Deprecated. Use JSONEscaper instead.
  @available(*, deprecated, message: "Use JSONEscaper().escape(_:) instead")
  public static func jsonEscape(_ string: String) -> String {
    let escaped =
      string
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\r", with: "\\r")
      .replacingOccurrences(of: "\t", with: "\\t")
      .replacingOccurrences(of: "\u{000C}", with: "\\f")
      .replacingOccurrences(of: "\u{0008}", with: "\\b")

    return escaped
  }
}
