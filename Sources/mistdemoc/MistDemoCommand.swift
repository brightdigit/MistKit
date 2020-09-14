import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token

extension UUID: ExpressibleByArgument {
  public init?(argument: String) {
    guard let uuid = UUID(uuidString: argument) else {
      return nil
    }
    self = uuid
  }
}

extension Result where Success == Void, Failure == Error {
  init(_ error: Error?) {
    if let error = error {
      self = .failure(error)
    } else {
      self = .success(())
    }
  }
}

protocol ParsableAsyncCommand: ParsableCommand {
  func runAsync(_ completed: @escaping (Error?) -> Void)
}

extension ParsableAsyncCommand {
  func run() throws {
    var result: Result<Void, Error>?

    runAsync { error in
      result = Result(error)
    }

    while true {
      RunLoop.main.run(until: .distantPast)
      if let result = result {
        return try result.get()
      }
    }
  }
}

struct MistDemoCommand: ParsableCommand {
  static var configuration = CommandConfiguration(commandName: "mistdemoc", subcommands: [ListCommand.self, NewCommand.self, FindCommand.self, DeleteCommand.self], defaultSubcommand: ListCommand.self)

  struct DeleteCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "delete")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var recordNames: [UUID] = []

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())
      if let token = options.token {
        manager.webAuthenticationToken = token
      }
      let database = MKDatabase(
        connection: dbConnection,
        factory: MKURLBuilderFactory(),
        client: client,
        tokenManager: manager
      )

      let query = LookupRecordQuery(TodoListItem.self, recordNames: recordNames)
      let request = LookupRecordQueryRequest(database: .private, query: query)
      database.lookup(request) { result in
        let items: [TodoListItem]
        do {
          items = try result.get()

        } catch {
          completed(error)
          return
        }
        let operations = items.map {
          ModifyOperation(operationType: .delete, record: $0)
        }

        let query = ModifyRecordQuery(operations: operations)

        let request = ModifyRecordQueryRequest(database: .private, query: query)
        database.perform(operations: request) { result in
          do {
            try print("Deleted \(result.get().deleted.count) items.")
          } catch {
            completed(error)
            return
          }
          completed(nil)
        }
      }
    }
  }

  struct FindCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "find")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var recordNames: [UUID] = []

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())
      if let token = options.token {
        manager.webAuthenticationToken = token
      }
      let database = MKDatabase(
        connection: dbConnection,
        factory: MKURLBuilderFactory(),
        client: client,
        tokenManager: manager
      )

      let query = LookupRecordQuery(TodoListItem.self, recordNames: recordNames)
      let request = LookupRecordQueryRequest(database: .private, query: query)
      database.lookup(request) { result in
        do {
          try print(result.get().information)
        } catch {
          completed(error)
          return
        }
        completed(nil)
      }
    }
  }

  struct NewCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "new")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var title: String

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())
      if let token = options.token {
        manager.webAuthenticationToken = token
      }
      let database = MKDatabase(
        connection: dbConnection,
        factory: MKURLBuilderFactory(),
        client: client,
        tokenManager: manager
      )
      let item = TodoListItem(title: title)

      let operation = ModifyOperation(operationType: .create, record: item)

      let query = ModifyRecordQuery(operations: [operation])

      let request = ModifyRecordQueryRequest(database: .private, query: query)
      database.perform(operations: request) { result in
        do {
          try print(result.get().updated.information)
        } catch {
          completed(error)
          return
        }
        completed(nil)
      }
    }
  }

  struct ListCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "list")
    @OptionGroup var options: MistDemoArguments

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())
      if let token = options.token {
        manager.webAuthenticationToken = token
      }
      let database = MKDatabase(
        connection: dbConnection,
        factory: MKURLBuilderFactory(),
        client: client,
        tokenManager: manager
      )
      let getTodosQuery = FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self)))
      database.query(getTodosQuery) { result in
        do {
          try print(result.get().information)
        } catch {
          completed(error)
          return
        }
        completed(nil)
      }
    }
  }
}
