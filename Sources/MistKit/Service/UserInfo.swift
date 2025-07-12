//
//  UserInfo.swift
//  MistKitExamples
//
//  Created by Leo Dion on 7/9/25.
//


// Helper models
public struct UserInfo: Encodable {
  public  let userRecordName: String
  public  let firstName: String?
  public  let lastName: String?
  public  let emailAddress: String?
    
  internal  init(from cloudKitUser: Components.Schemas.UserResponse) {
        self.userRecordName = cloudKitUser.userRecordName ?? "Unknown"
        self.firstName = cloudKitUser.firstName
        self.lastName = cloudKitUser.lastName
        self.emailAddress = cloudKitUser.emailAddress
    }
}
