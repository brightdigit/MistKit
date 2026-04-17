//
//  UserIdentity.swift
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

/// A user identity returned by CloudKit discover endpoints (users/discover, users/caller)
public struct UserIdentity: Codable, Sendable {
  public let userRecordName: String?
  public let nameComponents: NameComponents?
  public let lookupInfo: UserIdentityLookupInfo?

  internal init(from schema: Components.Schemas.UserIdentity) {
    self.userRecordName = schema.userRecordName
    self.nameComponents = schema.nameComponents.map(NameComponents.init(from:))
    self.lookupInfo = schema.lookupInfo.map(UserIdentityLookupInfo.init(from:))
  }

  public init(
    userRecordName: String? = nil,
    nameComponents: NameComponents? = nil,
    lookupInfo: UserIdentityLookupInfo? = nil
  ) {
    self.userRecordName = userRecordName
    self.nameComponents = nameComponents
    self.lookupInfo = lookupInfo
  }
}
