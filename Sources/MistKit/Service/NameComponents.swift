//
//  NameComponents.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

/// The parts of a user's name from CloudKit user discovery.
public struct NameComponents: Codable, Sendable {
  /// The name prefix (e.g., "Dr.", "Mr.")
  public let namePrefix: String?
  /// The given (first) name
  public let givenName: String?
  /// The middle name
  public let middleName: String?
  /// The family (last) name
  public let familyName: String?
  /// The name suffix (e.g., "Jr.", "III")
  public let nameSuffix: String?
  /// The nickname
  public let nickname: String?
  /// The phonetic representation of the name
  public let phoneticRepresentation: String?

  internal init(from schema: Components.Schemas.NameComponents) {
    self.namePrefix = schema.namePrefix
    self.givenName = schema.givenName
    self.middleName = schema.middleName
    self.familyName = schema.familyName
    self.nameSuffix = schema.nameSuffix
    self.nickname = schema.nickname
    self.phoneticRepresentation = schema.phoneticRepresentation
  }

  /// Initialize name components
  /// - Parameters:
  ///   - namePrefix: The name prefix
  ///   - givenName: The given name
  ///   - middleName: The middle name
  ///   - familyName: The family name
  ///   - nameSuffix: The name suffix
  ///   - nickname: The nickname
  ///   - phoneticRepresentation: The phonetic representation
  public init(
    namePrefix: String? = nil,
    givenName: String? = nil,
    middleName: String? = nil,
    familyName: String? = nil,
    nameSuffix: String? = nil,
    nickname: String? = nil,
    phoneticRepresentation: String? = nil
  ) {
    self.namePrefix = namePrefix
    self.givenName = givenName
    self.middleName = middleName
    self.familyName = familyName
    self.nameSuffix = nameSuffix
    self.nickname = nickname
    self.phoneticRepresentation = phoneticRepresentation
  }
}
