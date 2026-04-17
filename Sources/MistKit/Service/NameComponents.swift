//
//  NameComponents.swift
//  MistKit
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

/// The parts of a user's name from CloudKit user discovery
public final class NameComponents: Codable, Sendable {
  public let namePrefix: String?
  public let givenName: String?
  public let middleName: String?
  public let familyName: String?
  public let nameSuffix: String?
  public let nickname: String?
  public let phoneticRepresentation: NameComponents?

  internal init(from schema: Components.Schemas.NameComponents) {
    self.namePrefix = schema.namePrefix
    self.givenName = schema.givenName
    self.middleName = schema.middleName
    self.familyName = schema.familyName
    self.nameSuffix = schema.nameSuffix
    self.nickname = schema.nickname
    self.phoneticRepresentation = schema.phoneticRepresentation.map(NameComponents.init(from:))
  }

  public init(
    namePrefix: String? = nil,
    givenName: String? = nil,
    middleName: String? = nil,
    familyName: String? = nil,
    nameSuffix: String? = nil,
    nickname: String? = nil,
    phoneticRepresentation: NameComponents? = nil
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
