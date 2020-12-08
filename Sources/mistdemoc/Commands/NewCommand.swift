import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIO

public extension MistDemoCommand {
  struct NewCommand: ParsableAsyncCommand {
    public static var configuration = CommandConfiguration(commandName: "new")
    @OptionGroup var options: MistDemoArguments

    @Argument
    public var title: String

    public init() {}

    public func runAsync(_ completed: @escaping (Error?) -> Void) {
      // setup how to manager your user's web authentication token
      let manager = MKTokenManager(
        storage: MKUserDefaultsStorage(),
        client: MKNIOHTTP1TokenClient(bindTo: MistDemoCommand.defaultBinding)
      )

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
