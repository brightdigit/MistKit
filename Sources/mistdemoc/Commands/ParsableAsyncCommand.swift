import ArgumentParser
import Foundation

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
