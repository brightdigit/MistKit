import ArgumentParser
import Foundation
import MistKit
import MistKitNIOHTTP1Token

extension MKEnvironment: ExpressibleByArgument {}

struct MistDemoArguments: ParsableArguments {
  @Option()
  var apiKey = "c2b958e56ab5a41aa25d673f479bbac1379f1247d83199ccd94e38bb6ae715e2"

  @Option()
  var container = "iCloud.com.brightdigit.MistDemo"

  @Option()
  var environment = MKEnvironment.development

  @Option()
  var token: String?
}

struct MistDemoCommand: ParsableCommand {
  static var configuration = CommandConfiguration(commandName: "mistdemoc", subcommands: [ListCommand.self], defaultSubcommand: ListCommand.self)
  struct ListCommand: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "list")
    @OptionGroup var options: MistDemoArguments

    func run() throws {
      let dbConnection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      let client = MKURLSessionClient(session: .shared)

      let manager = MKNIOHTTP1TokenManager()
      manager.webAuthenticationToken = options.token
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

MistDemoCommand.main()
