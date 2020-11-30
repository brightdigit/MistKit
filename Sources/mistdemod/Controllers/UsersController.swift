import Vapor

struct UsersController: RouteCollection {
  func create(_ request: Request) throws -> EventLoopFuture<HTTPStatus> {
    let create = try request.content.decode(User.Create.self)
    let user = try User(
      name: create.name,
      passwordHash: Bcrypt.hash(create.password)
    )
    return user.save(on: request.db).transform(to: HTTPStatus.created)
  }

  func boot(routes: RoutesBuilder) throws {
    routes.post("users", use: create)
  }
}
