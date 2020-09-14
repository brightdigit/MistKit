import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token
extension MistDemoCommand {
  struct NewCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "new")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var title: String

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      // setup how to manager your user's web authentication token
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())

      // setup your database manager
      let database = MKDatabase(options: options, tokenManager: manager)

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
}
