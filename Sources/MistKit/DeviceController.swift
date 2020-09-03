//
// DeviceController.swift
// Copyright © 2020 Bright Digit, LLC.
// All Rights Reserved.
// Created by Leo G Dion.
//
//
import Foundation
//import Fluent
//import FluentPostgresDriver
//import HeartwitchKit
//import Vapor
struct Environment {
  
}
struct HTTPResponseStatus {
  
}
struct Abort {
  
}
struct User {
  
}
struct Request{
  
}
struct EventLoopFuture<T> {
  
}

struct DeviceControllerResponse<T> {
  
}
struct DeviceRegistrationRequest {
  
}

struct HTTPStatus {
  
}

struct HTTPHeaders {
  
}

struct DeviceController {
  let jsonDecoder = JSONDecoder()
  let ckEncoder: CloudKitTokenEncoder

  init(encoder: CloudKitTokenEncoder = CharacterMapEncoder()) {
    ckEncoder = encoder
  }

  func fetch(_ request: Request) { //throws -> EventLoopFuture<DeviceControllerResponse<[DeviceResponseItem]>> {
    //let user = try request.auth.require(User.self)
    //let userID = try user.requireID()
    let token = user.$appleUsers.query(on: request.db).first().map { appleUser in
      appleUser.map {
        self.ckEncoder.encode($0.webAuthenticationToken)
      }
    }

    guard let apiToken = Environment.get("CLOUDKIT_API_KEY") else {
      throw Abort(HTTPResponseStatus.notImplemented)
    }

    let environemntType = request.application.environment.isRelease ? "production" : "development"
    let containerName = "iCloud.com.brightdigit.Heartwitch"
    // user.appleUser
    let queryRequest = CloudKitQueryRequest(query: CloudKitQuery(recordType: "Device"), desiredKeys: nil)

    let url = token.map { (token) -> String in
      var url = "https://api.apple-cloudkit.com/database/1/" + containerName + "/" + environemntType + "/private/records/query?ckAPIToken=" + apiToken

      if let token = token {
        url.append("&ckSession=" + token)
      }
      return url
    }

    let ckResponse = url.flatMap { url in
      request.application.client.post(URI(string: url), headers: HTTPHeaders(), beforeSend: { request in
        try request.content.encode(queryRequest)
      })
    }

    let ckResult = ckResponse.flatMapThrowing { response in
      try Result {
        try response.content.decode(CloudKitQueryResponse.self, using: self.jsonDecoder).records.map { record in
          try Device(record: record, userID: userID)
        }
      }.map {
        DeviceControllerResponse<[Device]>.success($0)
      }.flatMapError { _ in
        Result {
          try response.content.decode(CloudKitErrorResponse.self, using: self.jsonDecoder)
        }.map { errorResponse in
          DeviceControllerResponse<[Device]>.failure(errorResponse.redirectURL)
        }
      }.get()
    }

    return ckResult.flatMap { (response) -> EventLoopFuture<DeviceControllerResponse<[DeviceResponseItem]>> in

      let devices: [Device]
      switch response {
      case let .failure(url):
        return request.eventLoop.makeSucceededFuture(.failure(url))
      case let .success(foundDevices):
        devices = foundDevices
      }

      let devicesFuture = Device.query(on: request.db)
        .filter("userID", .equal, userID)
        .all()
        .map { $0.map { ($0.identifier, $0) } }
        .map(Dictionary.init)

      let newDevicesList = devices.map { ($0.identifier, $0) }

      let newDevices = Dictionary(uniqueKeysWithValues: newDevicesList)

      return devicesFuture.flatMap { currentDevices in
        let deletingIds = [UUID](Set(currentDevices.keys).subtracting(newDevices.keys))
        let updatingIds = Set(currentDevices.keys).intersection(newDevices.keys)
        let creatingIds = Set(newDevices.keys).subtracting(currentDevices.keys)

        let creatingItems: [Device]
        let updatingItems: [Device]

        let deleting = Device.query(on: request.db).filter("userID", .equal, userID).filter(\.$identifier ~~ deletingIds).delete()

        updatingItems = updatingIds.compactMap { identifier in
          let device = currentDevices[identifier]
          if let newData = newDevices[identifier] {
            device?.merge(with: newData)
          }
          return device
        }

        creatingItems = creatingIds.compactMap {
          newDevices[$0]
        }

        let devices = updatingItems + creatingItems

        let saving = devices.map {
          $0.save(on: request.db)
        } + [deleting]

        return saving
          .flatten(on: request.eventLoop)
          .transform(to: DeviceControllerResponse<[DeviceResponseItem]>.success(devices.map(DeviceResponseItem.fromDevice(_:))))
      }
    }
  }

  func register(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
    let userID = try request.auth.require(User.self).requireID()
    let content = try request.content.decode(DeviceRegistrationRequest.self)

    return Device.query(on: request.db).filter("userID", .equal, userID).group(.or) {
      query in
      content.identifiers.forEach { id in
        query.filter("identifier", .equal, id)
      }
    }.all().flatMap { devices in
      devices.map { device in
        device.isRegistered = true
        return device.save(on: request.db)
      }.flatten(on: request.eventLoop)
    }.transform(to: HTTPStatus.accepted)
  }

  func remove(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
    let userID = try request.auth.require(User.self).requireID()
    let content = try request.content.decode(DeviceRegistrationRequest.self)

    return Device.query(on: request.db).filter("userID", .equal, userID).group(.or) {
      query in
      content.identifiers.forEach { id in
        query.filter("identifier", .equal, id)
      }
    }.all().flatMap { devices in
      devices.map { device in
        device.isRegistered = false
        return device.save(on: request.db)
      }.flatten(on: request.eventLoop)
    }.transform(to: HTTPStatus.accepted)
  }

  func check(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
    guard let identifier = request.parameters.get("identifier", as: UUID.self) else {
      return request.eventLoop.makeFailedFuture(Abort(.badRequest))
    }

    return Device.query(on: request.db).filter("identifier", .equal, identifier).filter(\.$isRegistered == true).first().map {
      $0 == nil ? HTTPStatus.notFound : HTTPStatus.ok
    }
  }
}
