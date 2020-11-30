import Fluent
import FluentSQLiteDriver
import MistKit
import MistKitDemo
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

public protocol MKModelStorable: Model {
  static var tokenKey: KeyPath<Self, Field<String?>> { get }
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

// let passwordProtected = app.grouped(User.authenticator())
// passwordProtected.post("login") { req -> User in
//    try req.auth.require(User.self)
// }

public class MKVaporModelStorage<ModelType: MKModelStorable>: MKTokenStorage {
  public let model: ModelType

  public init(model: ModelType) {
    self.model = model
  }

  public var webAuthenticationToken: String? {
    get {
      return model[keyPath: ModelType.tokenKey].wrappedValue
    }
    set {
      model[keyPath: ModelType.tokenKey].wrappedValue = newValue
    }
  }
}

public class MKVaporSessionStorage: MKTokenStorage {
  let session: Session
  let name: String

  public var webAuthenticationToken: String? {
    get {
      return session.data[name]
    }
    set {
      session.data[name] = newValue
    }
  }

  public init(session: Session, name: String = "ckWebAuthToken") {
    self.session = session
    self.name = name
  }
}

extension Request {
  var cloudKitAPI: MKTokenStorage {
    return MKVaporSessionStorage(session: session)
  }
}

extension MKDatabase where HttpClient == MKURLSessionClient {
  init(options: MistDemoArguments, tokenManager: MKTokenManagerProtocol) {
    // setup your connection to CloudKit
    let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

    // use the webAuthenticationToken which is passed
    if let token = options.token {
      tokenManager.webAuthenticationToken = token
    }

    self.init(
      connection: connection,
      tokenManager: tokenManager
    )
  }
}

struct MistDemoArguments {
  var apiKey = "eadc820055c358d8f261d561a93ac2c3ca962d3eca09d8b38c10c1e4beb05844"

  var container = "iCloud.com.brightdigit.MistDemo"

  var environment = MKEnvironment.development

  var token: String?
}

struct MKVaporTokenClientError: Error {}

class MKVaporTokenClient: MKTokenClient {
  func request(_: MKAuthenticationResponse?, _ callback: @escaping (Result<String, Error>) -> Void) {
    callback(.failure(MKVaporTokenClientError()))
  }
}

let app = try Application(.detect())
defer { app.shutdown() }

struct TodoItemModel: Content {
  let id: UUID?
  let title: String
  init(item: TodoListItem) {
    title = item.title
    id = item.recordName
  }
}

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

let tokenClient = MKVaporTokenClient()
app.databases.use(.sqlite(.memory), as: .sqlite)
app.middleware.use(app.sessions.middleware)
app.migrations.add(CreateUser())
try app.autoMigrate().wait()

let passwordProtected = app.grouped(User.authenticator())
passwordProtected.get("token") { (request) -> EventLoopFuture<HTTPStatus> in

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

app.post("users") { req -> EventLoopFuture<User> in
  let create = try req.content.decode(User.Create.self)
  let user = try User(
    name: create.name,
    passwordHash: Bcrypt.hash(create.password)
  )
  return user.save(on: req.db)
    .map { user }
}

public enum MKServerResponse<Success>: Codable where Success: Codable {
  public enum CodingKeys: String, CodingKey {
    case redirectURL
    case result
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    if container.contains(.result) {
      self = try .success(container.decode(Success.self, forKey: .result))
    } else if container.contains(.redirectURL) {
      self = try .failure(container.decode(URL.self, forKey: .redirectURL))
    } else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath, debugDescription: "No Valid Keys"))
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    switch self {
    case let .failure(url):
      try container.encode(url, forKey: .redirectURL)
    case let .success(data):
      try container.encode(data, forKey: .result)
    }
  }

  public init(fromResult result: Result<Success, Error>) throws {
    switch result {
    case let .success(value): self = .success(value)
    case let .failure(mkError as MKError):
      if case let MKError.authenticationRequired(redirect) = mkError {
        self = .failure(redirect.url)
      } else {
        throw mkError
      }
    case let .failure(error): throw error
    }
  }

  case failure(URL)
  case success(Success)
}

extension MKServerResponse: Content {}

passwordProtected.get("list") { req -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> in
  // setup how to manager your user's web authentication token

  let storage: MKTokenStorage
  if let user = req.auth.get(User.self) {
    storage = MKVaporModelStorage(model: user)
  } else {
    storage = req.cloudKitAPI
  }
  let manager = MKTokenManager(storage: storage, client: tokenClient)

  // setup your database manager
  let database = MKDatabase(options: MistDemoArguments(), tokenManager: manager)

  // create your request to CloudKit
  let query = MKQuery(recordType: TodoListItem.self)

  let request = FetchRecordQueryRequest(
    database: .private,
    query: FetchRecordQuery(query: query)
  )

  let promise = req.eventLoop.makePromise(of: MKServerResponse<[TodoItemModel]>.self)
  // handle the result
  database.query(request) { result in
    let serverResult = result.map { $0.map(TodoItemModel.init) }
    let actual = Result { try MKServerResponse(fromResult: serverResult) }

    promise.completeWith(actual)
    //    do {
    //      try print(result.get().information)
    //    } catch {
    //      //completed(error)
    //      return
    //    }
    // completed(nil)
  }
  return promise.futureResult
}

// app.get("list") { req -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> in
//  // setup how to manager your user's web authentication token
//
//  let storage : MKTokenStorage
//  if let user = req.auth.get(User.self) {
//    storage = MKVaporModelStorage(model: user)
//  } else {
//    storage = req.cloudKitAPI
//  }
//  let manager = MKTokenManager(storage: storage, client: tokenClient)
//
//  // setup your database manager
//  let database = MKDatabase(options: MistDemoArguments(), tokenManager: manager)
//
//  // create your request to CloudKit
//  let query = MKQuery(recordType: TodoListItem.self)
//
//  let request = FetchRecordQueryRequest(
//    database: .private,
//    query: FetchRecordQuery(query: query)
//  )
//
//  let promise = req.eventLoop.makePromise(of: MKServerResponse<[TodoItemModel]>.self)
//  // handle the result
//  database.query(request) { result in
//    let serverResult = result.map { $0.map(TodoItemModel.init) }
//    let actual = Result { try MKServerResponse(fromResult: serverResult) }
//
//    promise.completeWith(actual)
//    //    do {
//    //      try print(result.get().information)
//    //    } catch {
//    //      //completed(error)
//    //      return
//    //    }
//    // completed(nil)
//  }
//  return promise.futureResult
// }

try app.run()
