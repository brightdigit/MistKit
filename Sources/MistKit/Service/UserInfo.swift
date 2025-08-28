//
//  UserInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//

/// User information from CloudKit
public struct UserInfo: Encodable {
  /// The user's record name
  public let userRecordName: String
  /// The user's first name
  public let firstName: String?
  /// The user's last name
  public let lastName: String?
  /// The user's email address
  public let emailAddress: String?

  internal init(from cloudKitUser: Components.Schemas.UserResponse) {
    self.userRecordName = cloudKitUser.userRecordName ?? "Unknown"
    self.firstName = cloudKitUser.firstName
    self.lastName = cloudKitUser.lastName
    self.emailAddress = cloudKitUser.emailAddress
  }
}
