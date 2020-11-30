import Fluent

struct CreateUser: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(User.schema)
      .id()
      .field("name", .string, .required)
      .field("hash", .string, .required)
      .field("cloudKitToken", .string)
      .create()
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(User.schema).delete()
  }
}
