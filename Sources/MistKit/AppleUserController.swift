//
// AppleUserController.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//

import Foundation
//import Fluent
//import HeartwitchKit
//import Vapor

struct AppleUserController {
  let jsonDecoder = JSONDecoder()
  let ckEncoder: CloudKitTokenEncoder

  init(encoder: CloudKitTokenEncoder = CharacterMapEncoder()) {
    ckEncoder = encoder
  }

  func save(_ request: Request) throws -> EventLoopFuture<HTTPResponseStatus> {
    let userID = try request.auth.require(User.self).requireID()
    let tokenReq = try request.content.decode(AppleUserRequest.self)
    let appleUserFuture = AppleUser.query(on: request.db).filter("userID", .equal, userID).first()

    guard let apiToken = Environment.get("CLOUDKIT_API_KEY") else {
      throw Abort(HTTPResponseStatus.notImplemented)
    }

    let environemntType = request.application.environment.isRelease ? "production" : "development"
    let containerName = "iCloud.com.brightdigit.Heartwitch"
    // user.appleUser

    var url = "https://api.apple-cloudkit.com/database/1/" + containerName + "/" + environemntType + "/private/users/current?ckAPIToken=" + apiToken

    url.append("&ckSession=" + ckEncoder.encode(tokenReq.webAuthenticationToken))

    let userFuture: EventLoopFuture<CloudKitUserFetchResponse> = request.client.get(URI(string: url)).flatMapThrowing {
      dump($0)
      return try $0.content.decode(CloudKitUserFetchResponse.self, using: self.jsonDecoder)
    }

    return userFuture.and(appleUserFuture).flatMap { user, optAppleUser in
      let appleUser: AppleUser
      let created: Bool
      if let foundAppleUser = optAppleUser {
        appleUser = foundAppleUser
        appleUser.recordID = user.userRecordName
        appleUser.webAuthenticationToken = tokenReq.webAuthenticationToken
        created = false
      } else {
        appleUser = AppleUser(userID: userID, recordID: user.userRecordName, webAuthenticationToken: tokenReq.webAuthenticationToken)
        created = true
      }

      return appleUser.save(on: request.db).transform(to: created ? HTTPResponseStatus.created : HTTPResponseStatus.ok)
    }
  }
}
