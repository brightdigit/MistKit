import Fluent
import MistKitVapor
import Vapor

public final class User: Model, Content {
  public static let schema = "users"

  @ID(key: .id)
  public var id: UUID?

  @Field(key: "name")
  public var name: String

  @Field(key: "hash")
  public var passwordHash: String

  @Field(key: "cloudKitToken")
  public var cloudKitToken: String?

  public init() {}

  // swiftlint:disable:next function_default_parameter_at_end
  public init(id: UUID? = nil, name: String, passwordHash: String) {
    self.id = id
    self.name = name
    self.passwordHash = passwordHash
    cloudKitToken = nil
  }
}

public extension User {
  struct Create: Content {
    public var name: String
    public var password: String
  }
}

extension User: MKModelStorable {
  public static var tokenKey = \User.$cloudKitToken
}

extension User: ModelAuthenticatable {
  public static let usernameKey = \User.$name
  public static let passwordHashKey = \User.$passwordHash

  public func verify(password: String) throws -> Bool {
    try Bcrypt.verify(password, created: passwordHash)
  }
}
