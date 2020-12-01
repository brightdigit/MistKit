import FluentSQLiteDriver
import Vapor

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
