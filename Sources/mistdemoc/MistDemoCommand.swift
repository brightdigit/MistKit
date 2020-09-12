import ArgumentParser
import Foundation
import MistKit
import MistKitNIOHTTP1Token

extension Result {
  init(_ error: Error?) where Success == Void, Failure == Error {
    if let error = error {
      self = .failure(error)
    } else {
      self = .success(())
    }
  }
}

protocol ParsableAsyncCommand: ParsableCommand {
  func runAsync(_ completed: (Error?) -> Void)
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
  static var configuration = CommandConfiguration(commandName: "mistdemoc", subcommands: [ListCommand.self], defaultSubcommand: ListCommand.self)

  struct NewCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "list")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var title: String

    func runAsync(_: (Error?) -> Void) {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)
      let mistdemoURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".mistdemo")
      let manager = try MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())
      if let token = options.token {
        manager.webAuthenticationToken = token
      }
      let database = MKDatabase(
        connection: dbConnection,
        factory: MKURLBuilderFactory(),
        client: client,
        tokenManager: manager
      )

      var todoResult: Result<[TodoListItem], Error>?

      let getTodosQuery = FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self)))
      database.query(getTodosQuery) { result in
        todoResult = result
      }
    }
  }

  struct ListCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "list")
    @OptionGroup var options: MistDemoArguments

    func run() throws {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)
      let mistdemoURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".mistdemo")
      let manager = try MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())
      if let token = options.token {
        manager.webAuthenticationToken = token
      }
      let database = MKDatabase(
        connection: dbConnection,
        factory: MKURLBuilderFactory(),
        client: client,
        tokenManager: manager
      )

      var todoResult: Result<[TodoListItem], Error>?

      let getTodosQuery = FetchRecordQueryRequest(database: .private, query: FetchRecordQuery(query: MKQuery(recordType: TodoListItem.self)))
      database.query(getTodosQuery) { result in
        todoResult = result
      }

      while true {
        RunLoop.main.run(until: .distantPast)
        if let todoitems = todoResult {
          dump(todoitems)
          return
        }
      }
    }
  }
}
