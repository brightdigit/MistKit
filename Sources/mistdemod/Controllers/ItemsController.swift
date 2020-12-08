import MistKit
import MistKitDemo
import MistKitVapor
import Vapor

public struct ItemsController: RouteCollection {
  public func list(_ request: Request) -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> {
    // setup your database manager
    let database = MKDatabase(request: request)

    // create your request to CloudKit
    let query = MKQuery(recordType: TodoListItem.self)

    let cloudKitRequest = FetchRecordQueryRequest(
      database: .private,
      query: FetchRecordQuery(query: query)
    )

    return database.query(cloudKitRequest, on: request.eventLoop).content()
  }

  public func create(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>> {
    let title = try request.parameters.require("title")

    let database = MKDatabase(request: request)

    let item = TodoListItem(title: title)

    let operation = ModifyOperation(operationType: .create, record: item)

    let query = ModifyRecordQuery(operations: [operation])

    let cloudKitRequest = ModifyRecordQueryRequest(database: .private, query: query)

    return database.perform(operations: cloudKitRequest, on: request.eventLoop).content()
  }

  // delete
  public func delete(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>> {
    let id: UUID = try request.parameters.require("id")

    let database = MKDatabase(request: request)

    let query = LookupRecordQuery(TodoListItem.self, recordNames: [id])

    let cloudKitRequest = LookupRecordQueryRequest(database: .private, query: query)

    return database.lookup(cloudKitRequest, on: request.eventLoop).mapEach {
      ModifyOperation(operationType: .delete, record: $0)
    }
    .map(ModifyRecordQuery.init)
    .flatMap { query in
      database.perform(operations: ModifyRecordQueryRequest(database: .private, query: query), on: request.eventLoop)
    }.content()
  }

  // find
  public func find(_ request: Request) throws -> EventLoopFuture<MKServerResponse<[TodoItemModel]>> {
    let id: UUID = try request.parameters.require("id")

    let database = MKDatabase(request: request)

    let query = LookupRecordQuery(TodoListItem.self, recordNames: [id])

    let cloudKitRequest = LookupRecordQueryRequest(database: .private, query: query)

    return database.lookup(cloudKitRequest, on: request.eventLoop).content()
  }

  // rename
  public func rename(_ request: Request) throws -> EventLoopFuture<MKServerResponse<ModifiedRecordQueryContent<TodoItemModel>>> {
    let id: UUID = try request.parameters.require("id")
    let title = try request.parameters.require("title")

    let database = MKDatabase(request: request)

    let query = LookupRecordQuery(TodoListItem.self, recordNames: [id])

    let cloudKitRequest = LookupRecordQueryRequest(database: .private, query: query)

    return database.lookup(cloudKitRequest, on: request.eventLoop).mapEach { item in
      item.title = title
      return ModifyOperation(operationType: .update, record: item)
    }
    .map(ModifyRecordQuery<TodoListItem>.init)
    .flatMap { query in
      database.perform(operations: ModifyRecordQueryRequest(database: .private, query: query), on: request.eventLoop)
    }.content()
  }

  public func boot(routes: RoutesBuilder) throws {
    let items = routes.grouped("items")
    items.get([], use: list)
    items.post([":title"], use: create)
    items.get([":id"], use: find)
    items.delete([":id"], use: delete)
    items.patch([":id", ":title"], use: rename)
  }
}
