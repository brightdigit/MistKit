import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIO

public struct MistDemoCommand: ParsableCommand {
  public static var configuration = CommandConfiguration(
    commandName: "mistdemoc",
    subcommands: [
      ListCommand.self,
      NewCommand.self,
      FindCommand.self,
      DeleteCommand.self,
      RenameCommand.self,
      WhoAmICommand.self
    ], defaultSubcommand: ListCommand.self
  )

  public static let defaultBinding: BindTo = .ipAddress(host: "127.0.0.1", port: 7_000)

  public init() {}
}
