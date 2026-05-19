//
//  MistDemoRunner.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import ConfigKeyKit
internal import Foundation

/// Top-level driver for the `mistdemo` CLI. Registers all available commands,
/// parses arguments, and dispatches to the matching command — the executable
/// target's `@main` is reduced to a single call into `run()`.
public enum MistDemoRunner {
  /// Parse arguments and dispatch to the matching command.
  @MainActor
  public static func run() async throws {
    let registry = CommandRegistry.shared

    // Register available commands
    #if canImport(Hummingbird)
      await registry.register(AuthTokenCommand.self)
      await registry.register(WebCommand.self)
    #endif
    await registry.register(CurrentUserCommand.self)
    await registry.register(QueryCommand.self)
    await registry.register(CreateCommand.self)
    await registry.register(UpdateCommand.self)
    await registry.register(DeleteCommand.self)
    await registry.register(LookupCommand.self)
    await registry.register(ModifyCommand.self)
    await registry.register(UploadAssetCommand.self)
    await registry.register(DemoInFilterCommand.self)
    await registry.register(LookupZonesCommand.self)
    await registry.register(CreateZoneCommand.self)
    await registry.register(ListZonesCommand.self)
    await registry.register(ModifyZonesCommand.self)
    await registry.register(DiscoverCommand.self)
    await registry.register(ValidateCommand.self)
    await registry.register(DeleteZoneCommand.self)
    await registry.register(FetchChangesCommand.self)
    await registry.register(TestPublicCommand.self)
    await registry.register(TestPrivateCommand.self)
    await registry.register(DemoErrorsCommand.self)

    // Parse command line arguments
    let parser = CommandLineParser()

    // Check for help
    if parser.isHelpRequested() {
      if let commandName = parser.parseCommandName() {
        await printCommandHelp(commandName, registry: registry)
      } else {
        await printGeneralHelp(registry: registry)
      }
      return
    }

    // Check if a command was specified
    if let commandName = parser.parseCommandName() {
      try await executeCommand(commandName, registry: registry)
    } else {
      await printMissingCommandError(registry: registry)
    }
  }

  /// Execute a specific command
  private static func executeCommand(_ commandName: String, registry: CommandRegistry) async throws
  {
    do {
      let command = try await registry.createCommand(named: commandName)
      try await command.execute()
    } catch let error as CommandRegistryError {
      print("❌ \(error.localizedDescription)")
      let availableCommands = await registry.availableCommands
      print("Available commands: \(availableCommands.joined(separator: ", "))")
      print("Run 'mistdemo help' for usage information.")
      throw error
    }
  }

  /// Print general help
  @MainActor
  private static func printGeneralHelp(registry: CommandRegistry) async {
    print("MistDemo - CloudKit Web Services Command Line Tool")
    print("")
    print("USAGE:")
    print("    mistdemo <command> [options]")
    print("")
    print("COMMANDS:")
    let availableCommands = await registry.availableCommands
    for commandName in availableCommands {
      if let metadata = await registry.metadata(for: commandName) {
        let paddedName = commandName.padding(toLength: 12, withPad: " ", startingAt: 0)
        print("    \(paddedName) \(metadata.abstract)")
      }
    }
    print("")
    print("OPTIONS:")
    print("    --help, -h    Show help information")
    print("")
    print("Run 'mistdemo <command> --help' for command-specific help.")
  }

  /// Print command-specific help
  @MainActor
  private static func printCommandHelp(_ commandName: String, registry: CommandRegistry) async {
    if let metadata = await registry.metadata(for: commandName) {
      print(metadata.helpText)
    } else {
      print("Unknown command: \(commandName)")
      await printGeneralHelp(registry: registry)
    }
  }

  /// Print error when no command is specified
  @MainActor
  private static func printMissingCommandError(registry: CommandRegistry) async {
    print("❌ No command specified.")
    print("💡 Use the command-based interface:")
    print("")
    await printGeneralHelp(registry: registry)
  }
}
