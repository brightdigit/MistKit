import Fluent
import FluentSQLiteDriver
import MistKit
import MistKitDemo
import MistKitVapor
import Vapor

extension Application {
  var cloudKitAPIKey: String {
    return "eadc820055c358d8f261d561a93ac2c3ca962d3eca09d8b38c10c1e4beb05844"
  }
}

extension Request {
  var cloudKitAPI: MKTokenStorage {
    return MKVaporSessionStorage(session: session)
  }
}

extension MKDatabase where HttpClient == MKURLSessionClient {
  @available(*, deprecated)
  init(options: MistDemoConfiguration, tokenManager: MKTokenManagerProtocol) {
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

let app = try Application(.detect())
defer { app.shutdown() }
app.databases.use(.sqlite(.memory), as: .sqlite)
app.middleware.use(app.sessions.middleware)
app.migrations.add(CreateUser())
try app.autoMigrate().wait()
try app.register(collection: UsersController())
let basicAuth = app.grouped(User.authenticator())
try basicAuth.register(collection: CloudKitController())
try basicAuth.register(collection: ItemsController())
try app.run()
