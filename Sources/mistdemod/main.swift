import FluentSQLiteDriver
import Vapor

internal let app = try Application(.detect())
internal let basicAuth = app.grouped(User.authenticator())

defer { app.shutdown() }
app.databases.use(.sqlite(.memory), as: .sqlite)
app.middleware.use(app.sessions.middleware)
app.migrations.add(CreateUser())
try app.autoMigrate().wait()
try app.register(collection: UsersController())
try basicAuth.register(collection: CloudKitController())
try basicAuth.register(collection: ItemsController())
try app.run()
