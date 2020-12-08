import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIO

public extension MistDemoCommand {
  struct DeleteCommand: ParsableAsyncCommand {
    public static var configuration = CommandConfiguration(commandName: "delete")
    @OptionGroup public var options: MistDemoArguments

    @Argument
    public var recordNames: [UUID] = []

    public init() {}

    // swiftlint:disable:next function_body_length
    public func runAsync(_ completed: @escaping (Error?) -> Void) {
      // setup how to manager your user's web authentication token
      let manager = MKTokenManager(
        storage: MKUserDefaultsStorage(),
        client: MKNIOHTTP1TokenClient(bindTo: MistDemoCommand.defaultBinding)
      )

      // setup your database manager
      let database = MKDatabase(options: options, tokenManager: manager)

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
}
