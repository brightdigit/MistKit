import ArgumentParser
import Foundation

// MARK: - Bushel

/// Bushel - A CloudKit version history management tool
@main
struct Bushel: AsyncParsableCommand {
  // MARK: Internal

  static let configuration = CommandConfiguration(
    abstract: "A CloudKit version history management tool powered by MistKit",
    version: "1.0.0",
    subcommands: [
      Add.self,
      List.self,
      Show.self,
      Update.self,
      Delete.self,
    ],
    defaultSubcommand: List.self
  )
}
