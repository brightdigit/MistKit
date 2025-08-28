//
//  CharacterMapEncoder.swift
//  PackageDSLKit
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

import Foundation

/// A token encoder that replaces specific characters with URL-encoded equivalents
public struct CharacterMapEncoder: Sendable {
  /// Default character map for CloudKit web authentication tokens
  public static let defaultCharacterMap: [Character: String] = [
    "+": "%2B",
    "/": "%2F",
    "=": "%3D",
  ]

  /// Character mapping for encoding tokens
  private let characterMap: [Character: String]

  /// Initialize with a custom character map
  /// - Parameter characterMap: The character mapping to use for encoding
  public init(characterMap: [Character: String] = defaultCharacterMap) {
    self.characterMap = characterMap
  }

  /// Encode a token by replacing characters according to the character map
  /// - Parameter token: The token to encode
  /// - Returns: The encoded token with characters replaced
  public func encode(_ token: String) -> String {
    var encodedToken = token

    for (character, replacement) in characterMap {
      encodedToken = encodedToken.replacingOccurrences(of: String(character), with: replacement)
    }

    return encodedToken
  }
}
