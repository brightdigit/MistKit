import ArgumentParser
import Foundation

// MARK: - Bushel.Add

extension Bushel {
  struct Add: AsyncParsableCommand {
    // MARK: Internal

    static let configuration = CommandConfiguration(
      abstract: "Add a new version to CloudKit"
    )

    @Option(name: .shortAndLong, help: "Version string (e.g., 1.2.3)")
    var version: String

    @Option(name: .shortAndLong, help: "Release notes")
    var notes: String

    @Option(name: .long, help: "Release status (draft, released, deprecated)")
    var status: String = "released"

    @Option(name: .long, help: "Build number")
    var buildNumber: String?

    @Option(name: .long, help: "Git commit hash")
    var commitHash: String?

    @Option(name: .long, help: "Configuration file path")
    var config: String?

    func run() async throws {
      print("Add command - to be implemented")
      // TODO: Implement in next subtask (5.3)
    }
  }
}
