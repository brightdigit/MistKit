//
//  UserIdentityLookupInfo.swift
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

internal import Foundation
internal import MistKitOpenAPI

/// Information used to look up a user identity from CloudKit.
///
/// Composes ``ContactInformation`` (email / phone) with an optional user
/// record name. Codable keeps the CloudKit wire shape flat —
/// `emailAddress`, `phoneNumber`, and `userRecordName` at the top level —
/// rather than nesting contact fields.
public struct UserIdentityLookupInfo: Codable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case emailAddress
    case phoneNumber
    case userRecordName
  }

  /// Contact details used to look up the user.
  public let contactInformation: ContactInformation?
  /// The user record name to look up
  public let userRecordName: String?

  /// The email address to look up
  public var emailAddress: String? { contactInformation?.emailAddress }
  /// The phone number to look up
  public var phoneNumber: String? { contactInformation?.phoneNumber }

  internal init(from schema: Components.Schemas.UserIdentityLookupInfo) {
    self.init(
      emailAddress: schema.emailAddress,
      phoneNumber: schema.phoneNumber,
      userRecordName: schema.userRecordName
    )
  }

  /// Initialize lookup info from contact details and an optional record name.
  /// - Parameters:
  ///   - contactInformation: Email and/or phone for the lookup.
  ///   - userRecordName: The user record name to look up.
  public init(
    contactInformation: ContactInformation?,
    userRecordName: String? = nil
  ) {
    self.contactInformation = contactInformation
    self.userRecordName = userRecordName
  }

  /// Initialize lookup info with optional identifiers
  /// - Parameters:
  ///   - emailAddress: The email address to look up
  ///   - phoneNumber: The phone number to look up
  ///   - userRecordName: The user record name to look up
  public init(
    emailAddress: String? = nil,
    phoneNumber: String? = nil,
    userRecordName: String? = nil
  ) {
    if emailAddress != nil || phoneNumber != nil {
      self.contactInformation = ContactInformation(
        emailAddress: emailAddress,
        phoneNumber: phoneNumber
      )
    } else {
      self.contactInformation = nil
    }
    self.userRecordName = userRecordName
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let emailAddress = try container.decodeIfPresent(String.self, forKey: .emailAddress)
    let phoneNumber = try container.decodeIfPresent(String.self, forKey: .phoneNumber)
    let userRecordName = try container.decodeIfPresent(String.self, forKey: .userRecordName)
    self.init(
      emailAddress: emailAddress,
      phoneNumber: phoneNumber,
      userRecordName: userRecordName
    )
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(emailAddress, forKey: .emailAddress)
    try container.encodeIfPresent(phoneNumber, forKey: .phoneNumber)
    try container.encodeIfPresent(userRecordName, forKey: .userRecordName)
  }
}

extension Components.Schemas.UserIdentityLookupInfo {
  internal init(from lookupInfo: UserIdentityLookupInfo) {
    self.init(
      emailAddress: lookupInfo.emailAddress,
      phoneNumber: lookupInfo.phoneNumber,
      userRecordName: lookupInfo.userRecordName
    )
  }
}
