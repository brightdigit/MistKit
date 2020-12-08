import MistKit
import MistKitNIO
import Vapor

public struct UsersController: RouteCollection {
  public func create(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
    let create = try request.content.decode(User.Create.self)
    let user = try User(
      name: create.name,
      passwordHash: Bcrypt.hash(create.password)
    )
    return user.save(on: request.db).transform(to: HTTPStatus.created)
  }

  // whoami

  public func get(_ request: Request) throws -> EventLoopFuture<MKServerResponse<UserIdentityResponse>> {
    let database = MKDatabase(request: request)
    return database.perform(request: GetCurrentUserIdentityRequest(), on: request.eventLoop).mistKitResponse()
  }

  public func boot(routes: RoutesBuilder) throws {
    let users = routes.grouped("users")
    users.grouped(User.authenticator()).get([], use: get)
    users.post([], use: create)
  }
}
