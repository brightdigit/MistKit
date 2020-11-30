import MistKit
import MistKitDemo
import MistKitVapor
import Vapor

struct ItemsController: RouteCollection {
  func list(_ request: Request) -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> {
    // setup how to manager your user's web authentication token

    let storage: MKTokenStorage
    if let user = request.auth.get(User.self) {
      storage = MKVaporModelStorage(model: user)
    } else {
      storage = request.cloudKitAPI
    }
    let manager = MKTokenManager(storage: storage, client: nil)

    // setup your database manager
    let database = MKDatabase(options: MistDemoDefaultConfiguration(apiKey: request.application.cloudKitAPIKey), tokenManager: manager)

    // create your request to CloudKit
    let query = MKQuery(recordType: TodoListItem.self)

    let cloudKitRequest = FetchRecordQueryRequest(
      database: .private,
      query: FetchRecordQuery(query: query)
    )

    let promise = request.eventLoop.makePromise(of: MKServerResponse<[TodoItemModel]>.self)
    // handle the result
    database.query(cloudKitRequest) { result in
      let serverResult = result.map { $0.map(TodoItemModel.init) }
      let actual = Result { try MKServerResponse(fromResult: serverResult) }

      promise.completeWith(actual)
    }
    return promise.futureResult
  }

  func create(_ request: Request) throws -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> {
    let storage: MKTokenStorage

    let title = try request.parameters.require("title")
    if let user = request.auth.get(User.self) {
      storage = MKVaporModelStorage(model: user)
    } else {
      storage = request.cloudKitAPI
    }
    let manager = MKTokenManager(storage: storage, client: nil)

    // setup your database manager
    let database = MKDatabase(options: MistDemoDefaultConfiguration(apiKey: request.application.cloudKitAPIKey), tokenManager: manager)

    let item = TodoListItem(title: title)

    let operation = ModifyOperation(operationType: .create, record: item)

    let query = ModifyRecordQuery(operations: [operation])

    let cloudKitRequest = ModifyRecordQueryRequest(database: .private, query: query)

    let promise = request.eventLoop.makePromise(of: MKServerResponse<[TodoItemModel]>.self)
    // handle the result
    database.perform(operations: cloudKitRequest) { result in
      let serverResult = result.map { $0.updated.map(TodoItemModel.init) }
      let actual = Result { try MKServerResponse(fromResult: serverResult) }
      promise.completeWith(actual)
    }
    return promise.futureResult
  }

  func boot(routes: RoutesBuilder) throws {
    routes.get(["items"], use: list)
    routes.get(["items", ":title"], use: create)
  }
}
