//
// RecordNameParser.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation

public struct RecordNameParser {
  static let componentSizes = [8, 4, 4, 4, 12]
  static func regexComponent(forLength length: Int) -> String {
    "([0-9A-F]{\(length)})"
  }

  public init () {
    
  }
  static let regexStrInner = componentSizes.map(regexComponent(forLength:)).joined(separator: "")
  static let regexString = "^_\(regexStrInner)$"
  // swiftlint:disable:next force_try
  static let regex = try! NSRegularExpression(pattern: regexString, options: .caseInsensitive)
  public static func uuid(fromRecordName recordName: String) -> UUID? {
    if let uuid = UUID(uuidString: recordName) {
      return uuid
    }
    let match = regex.firstMatch(in: recordName, options: NSRegularExpression.MatchingOptions(), range: .init(location: 0, length: recordName.count))

    let uuidStringComponents = componentSizes.enumerated().compactMap { (index, _) -> Substring? in
      let nsRange = match?.range(at: index + 1)
      return nsRange.flatMap {
        Range($0, in: recordName)
      }.map {
        recordName[$0]
      }
    }

    if uuidStringComponents.count == componentSizes.count {
      return UUID(uuidString: uuidStringComponents.joined(separator: "-"))

    } else {
      return nil
    }
  }
}
