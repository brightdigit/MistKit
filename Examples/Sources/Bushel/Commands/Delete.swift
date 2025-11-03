import ArgumentParser
import Foundation

// MARK: - Bushel.Delete

extension Bushel {
  struct Delete: AsyncParsableCommand {
    // MARK: Internal

    static let configuration = CommandConfiguration(
      abstract: "Delete a version from CloudKit"
    )

    @Argument(help: "Version string to delete (e.g., 1.2.3)")
    var version: String

    @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
    var force = false

    @Option(name: .long, help: "Configuration file path")
    var config: String?

    func run() async throws {
      print("Delete command - to be implemented")
      // TODO: Implement in next subtask (5.3)
    }
  }
}
