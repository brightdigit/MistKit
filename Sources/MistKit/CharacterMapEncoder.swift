//
// CharacterMapEncoder.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

public struct CharacterMapEncoder: CloudKitTokenEncoder {
  public static let defaultCharacterMap = ["+": "%2B", "/": "%2F", "=": "%3D"]
  let characterMap: [String: String]

  public init(characterMap: [String: String] = defaultCharacterMap) {
    self.characterMap = characterMap
  }

  public func encode(_ token: String) -> String {
    var encodedString = token

    for (find, replace) in characterMap {
      encodedString = encodedString.replacingOccurrences(of: find, with: replace)
    }

    return encodedString
  }
}
