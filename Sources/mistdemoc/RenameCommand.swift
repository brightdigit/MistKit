import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token

extension MistDemoCommand {
  struct RenameCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "rename")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var recordName: UUID

    @Argument
    var newTitle: String

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

      let query = LookupRecordQuery(TodoListItem.self, recordNames: [recordName])
      let request = LookupRecordQueryRequest(database: .private, query: query)
      database.lookup(request) { result in
        let items: [TodoListItem]
        do {
          items = try result.get()

        } catch {
          completed(error)
          return
        }
        let operations = items.map { (item) -> ModifyOperation<TodoListItem> in
          item.title = self.newTitle
          return ModifyOperation(operationType: .update, record: item)
        }

        let query = ModifyRecordQuery(operations: operations)

        let request = ModifyRecordQueryRequest(database: .private, query: query)
        database.perform(operations: request) { result in
          do {
            try print("Updated \(result.get().updated.count) items.")
          } catch {
            completed(error)
            return
          }
          completed(nil)
        }
      }
    }
  }
}
