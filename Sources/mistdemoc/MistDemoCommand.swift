import ArgumentParser
import Foundation
import MistKit
import MistKitDemo
import MistKitNIOHTTP1Token

struct MistDemoCommand: ParsableCommand {
  static var configuration = CommandConfiguration(commandName: "mistdemoc", subcommands: [ListCommand.self, NewCommand.self, FindCommand.self, DeleteCommand.self], defaultSubcommand: ListCommand.self)
}
