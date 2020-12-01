import Fluent
import MistKitVapor
import Vapor

final class User: Model, Content {
  static let schema = "users"

  @ID(key: .id)
  var id: UUID?

  @Field(key: "name")
  var name: String

  @Field(key: "hash")
  var passwordHash: String

  @Field(key: "cloudKitToken")
  var cloudKitToken: String?

  init() {}

  init(id: UUID? = nil, name: String, passwordHash: String) {
    self.id = id
    self.name = name
    self.passwordHash = passwordHash
    cloudKitToken = nil
  }
}

extension User {
  struct Create: Content {
    var name: String
    var password: String
  }
}

extension User: MKModelStorable {
  static var tokenKey: KeyPath<User, Field<String?>> = \User.$cloudKitToken
}

extension User: ModelAuthenticatable {
  static let usernameKey = \User.$name
  static let passwordHashKey = \User.$passwordHash

  func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: passwordHash)
  }
}
