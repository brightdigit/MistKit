import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token

struct MistDemoCommand: ParsableCommand {
  static var configuration = CommandConfiguration(commandName: "mistdemoc", subcommands: [ListCommand.self, NewCommand.self, FindCommand.self, DeleteCommand.self, RenameCommand.self, WhoAmICommand.self], defaultSubcommand: ListCommand.self)

  static let defaultBinding: BindTo = .ipAddress(host: "127.0.0.1", port: 7000)
}
