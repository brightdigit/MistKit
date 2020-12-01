import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIO

extension MistDemoCommand {
  struct FindCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "find")
    @OptionGroup var options: MistDemoArguments

    @Argument
    var recordNames: [UUID] = []

    @Flag
    var record: Bool = false

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      // setup how to manager your user's web authentication token
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient(bindTo: MistDemoCommand.defaultBinding))

      // setup your database manager
      let database = MKDatabase(options: options, tokenManager: manager)

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
