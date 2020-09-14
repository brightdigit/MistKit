import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token
extension MistDemoCommand {
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
}
