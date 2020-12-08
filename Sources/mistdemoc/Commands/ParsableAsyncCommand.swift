import ArgumentParser
import CoreFoundation
import Foundation

public protocol ParsableAsyncCommand: ParsableCommand {
  func runAsync(_ completed: @escaping (Error?) -> Void)
}

public extension ParsableAsyncCommand {
  func run() throws {
    var result: Result<Void, Error>!

    runAsync { error in
      result = Result(error)
      CFRunLoopStop(CFRunLoopGetMain())
    }

    CFRunLoopRun()

    return try result.get()
  }
}
