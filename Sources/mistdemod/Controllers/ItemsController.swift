import MistKit
import MistKitDemo
import MistKitVapor
import Vapor

extension TodoListItem: MKContentRecord {
  public static func content(fromRecord record: TodoListItem) -> TodoItemModel {
    return TodoItemModel(item: record)
  }

  public typealias ContentType = TodoItemModel
}

struct ItemsController: RouteCollection {
  func list(_ request: Request) -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> {
    // setup your database manager
    let database = MKDatabase(request: request)

    // create your request to CloudKit
    let query = MKQuery(recordType: TodoListItem.self)

    let cloudKitRequest = FetchRecordQueryRequest(
      database: .private,
      query: FetchRecordQuery(query: query)
    )

    return database.query(cloudKitRequest, on: request.eventLoop)
  }

  func create(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>> {
    let title = try request.parameters.require("title")

    let database = MKDatabase(request: request)

    let item = TodoListItem(title: title)

    let operation = ModifyOperation(operationType: .create, record: item)

    let query = ModifyRecordQuery(operations: [operation])

    let cloudKitRequest = ModifyRecordQueryRequest(database: .private, query: query)

    return database.perform(operations: cloudKitRequest, on: request.eventLoop)
  }

  func boot(routes: RoutesBuilder) throws {
    routes.get(["items"], use: list)
    routes.post(["items", ":title"], use: create)
  }
}
