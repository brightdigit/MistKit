//
//  ContactInformation.swift
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

/// Contact details CloudKit associates with a person — email and/or phone.
///
/// Used by share potential-match disambiguation (``SharePotentialMatch``) and
/// composed into ``UserIdentityLookupInfo`` (which also carries a user record
/// name). On the wire, lookup info stays flat; share potential matches nest
/// these keys under `contactInformation`.
public struct ContactInformation: Codable, Sendable, Equatable, Hashable {
  /// The email address, when known.
  public let emailAddress: String?
  /// The phone number, when known.
  public let phoneNumber: String?

  /// Initialize contact information.
  /// - Parameters:
  ///   - emailAddress: The email address.
  ///   - phoneNumber: The phone number.
  public init(emailAddress: String? = nil, phoneNumber: String? = nil) {
    self.emailAddress = emailAddress
    self.phoneNumber = phoneNumber
  }
}
