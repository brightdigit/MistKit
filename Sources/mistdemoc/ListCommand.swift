import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token
extension MistDemoCommand {
  struct ListCommand: ParsableAsyncCommand {
    static var configuration = CommandConfiguration(commandName: "list")
    @OptionGroup var options: MistDemoArguments

    @Flag
    var record: Bool = false

    func runAsync(_ completed: @escaping (Error?) -> Void) {
      let connection = MKDatabaseConnection(container: options.container, apiToken: options.apiKey, environment: options.environment)

      // setup how to manager your user's web authentication token
      let manager = MKTokenManager(storage: MKUserDefaultsStorage(), client: MKNIOHTTP1TokenClient())

      // setup your database manager
      let database = MKDatabase(
        connection: connection,
        tokenManager: manager
      )

      if record {
        // create your request to CloudKit
        let query = MKAnyQuery(recordType: TodoListItem.recordType)

        let request = FetchRecordQueryRequest(
          database: .private,
          query: FetchRecordQuery(query: query)
        )

        // handle the result
        database.perform(request: request) { result in
          do {
            try print(result.get().records.information)
          } catch {
            completed(error)
            return
          }
          completed(nil)
        }

      } else {
        // create your request to CloudKit
        let query = MKQuery(recordType: TodoListItem.self)

        let request = FetchRecordQueryRequest(
          database: .private,
          query: FetchRecordQuery(query: query)
        )

        // handle the result
        database.query(request) { result in
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
}
