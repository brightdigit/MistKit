import Vapor

public struct CloudKitController: RouteCollection {
  public func token(_ request: Request) -> EventLoopFuture<HTTPStatus> {
    guard let token: String = request.query["ckWebAuthToken"] else {
      return request.eventLoop.makeSucceededFuture(.notFound)
    }

    guard let user = request.auth.get(User.self) else {
      request.cloudKitAPI.webAuthenticationToken = token
      return request.eventLoop.makeSucceededFuture(.accepted)
    }

    user.cloudKitToken = token
    return user.save(on: request.db).transform(to: .accepted)
  }

  public func boot(routes: RoutesBuilder) throws {
    routes.get(["token"], use: token)
  }
}
