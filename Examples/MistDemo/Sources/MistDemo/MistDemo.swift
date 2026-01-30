//
//  MistDemo.swift
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

import Foundation
import Hummingbird
import Logging
import MistKit
import UnixSignals
import ConfigKeyKit

#if canImport(AppKit)
import AppKit
#endif

@main
struct MistDemo {
  @MainActor
  static func main() async throws {
    // Register available commands
    CommandRegistry.register(AuthTokenCommand.self)
    CommandRegistry.register(CurrentUserCommand.self)
    CommandRegistry.register(QueryCommand.self)
    CommandRegistry.register(CreateCommand.self)
    
    // Parse command line arguments
    let parser = CommandLineParser()
    
    // Check for help
    if parser.isHelpRequested() {
      if let commandName = parser.parseCommandName() {
        await printCommandHelp(commandName)
      } else {
        await printGeneralHelp()
      }
      return
    }
    
    // Check if a command was specified
    if let commandName = parser.parseCommandName() {
      // Execute specific command
      try await executeCommand(commandName)
    } else {
      // Fall back to legacy behavior for backward compatibility
      try await executeLegacyMode()
    }
  }
  
  /// Execute a specific command
  private static func executeCommand(_ commandName: String) async throws {
    switch commandName {
    case "auth-token":
      let command = try AuthTokenCommand()
      try await command.execute()
    case "current-user":
      let command = try CurrentUserCommand()
      try await command.execute()
    case "query":
      let command = try QueryCommand()
      try await command.execute()
    case "create":
      let command = try CreateCommand()
      try await command.execute()
    default:
      print("❌ Unknown command: \(commandName)")
      print("Available commands: \(await CommandRegistry.availableCommands.joined(separator: ", "))")
      print("Run 'mistdemo help' for usage information.")
      throw MistDemoError.unknownCommand(commandName)
    }
  }
  
  /// Print general help
  @MainActor
  private static func printGeneralHelp() {
    print("MistDemo - CloudKit Web Services Command Line Tool")
    print("")
    print("USAGE:")
    print("    mistdemo <command> [options]")
    print("")
    print("COMMANDS:")
    for commandName in CommandRegistry.availableCommands {
      switch commandName {
      case "auth-token":
        print("    \(commandName)    \(AuthTokenCommand.abstract)")
      case "current-user":
        print("    \(commandName)  \(CurrentUserCommand.abstract)")
      case "query":
        print("    \(commandName)         \(QueryCommand.abstract)")
      case "create":
        print("    \(commandName)        \(CreateCommand.abstract)")
      default:
        print("    \(commandName)")
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
  private static func printCommandHelp(_ commandName: String) async {
    switch commandName {
    case "auth-token":
      AuthTokenCommand.printHelp()
    case "current-user":
      CurrentUserCommand.printHelp()
    case "query":
      QueryCommand.printHelp()
    case "create":
      CreateCommand.printHelp()
    default:
      print("Unknown command: \(commandName)")
      await printGeneralHelp()
    }
  }
  
  /// Execute legacy mode for backward compatibility
  private static func executeLegacyMode() async throws {
    print("❌ Legacy mode has been removed.")
    print("💡 Use the new command-based interface:")
    print("")
    print("Available commands:")
    print("  mistdemo auth-token     - Get authentication token")
    print("  mistdemo current-user   - Get current user info")
    print("  mistdemo query          - Query CloudKit records")
    print("  mistdemo create         - Create CloudKit records")
    print("")
    print("Run 'mistdemo <command> --help' for detailed help.")
    print("Or 'mistdemo --help' for general help.")
  }
}