//
//  YAMLEscaper.swift
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

/// YAML escaper for proper string formatting
public struct YAMLEscaper: OutputEscaper {
    public init() {}

    public func escape(_ string: String) -> String {
        // Check if the string needs escaping
        guard needsEscaping(string) else {
            return string
        }

        // For multi-line strings, use literal block scalar
        if string.contains("\n") {
            return blockScalar(string)
        }

        // For single-line strings with special characters, use double quotes
        let escaped = string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\t", with: "\\t")
            .replacingOccurrences(of: "\r", with: "\\r")

        return "\"\(escaped)\""
    }

    // MARK: - Private Helpers

    /// Check if a string needs YAML escaping
    private func needsEscaping(_ string: String) -> Bool {
        // Empty strings need quotes
        if string.isEmpty {
            return true
        }

        // Check for YAML special characters and patterns
        let specialChars: Set<Character> = [
            ":", "#", "@", "`", "|", ">", "'", "\"",
            "[", "]", "{", "}", ",", "&", "*", "!",
            "%", "\\", "?", "-", "<", "=", "~"
        ]

        // Check first character for special cases
        if let first = string.first {
            if specialChars.contains(first) || first.isWhitespace {
                return true
            }
        }

        // Check last character for whitespace
        if let last = string.last, last.isWhitespace {
            return true
        }

        // Check for special patterns
        let specialPatterns = [
            "yes", "no", "true", "false", "on", "off",
            "null", "~", "YES", "NO", "TRUE", "FALSE",
            "ON", "OFF", "NULL", "Yes", "No", "True",
            "False", "On", "Off", "Null"
        ]

        if specialPatterns.contains(string) {
            return true
        }

        // Check if it looks like a number
        if Double(string) != nil || Int(string) != nil {
            return true
        }

        // Check for special characters in the string
        for char in string {
            if specialChars.contains(char) || char == "\n" || char == "\r" || char == "\t" {
                return true
            }
        }

        return false
    }

    /// Create a YAML block scalar for multi-line strings
    private func blockScalar(_ string: String) -> String {
        // Use literal block scalar (|) for multi-line strings
        // This preserves line breaks and doesn't require escaping
        let lines = string.split(separator: "\n", omittingEmptySubsequences: false)

        // Use literal scalar to preserve formatting
        var result = "|\n"

        // Indent each line with 2 spaces (or 4 spaces for better readability)
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
}
