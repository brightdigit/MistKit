//
//  MistDemoCommand.swift
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

/// Protocol for MistDemo commands using Swift Configuration
public protocol MistDemoCommand: Sendable {
    /// Command name for CLI parsing
    static var commandName: String { get }
    
    /// Abstract description of the command
    static var abstract: String { get }
    
    /// Execute the command asynchronously
    func execute() async throws
}

/// Command configuration for identifying and routing commands
public struct CommandConfiguration {
    public let commandName: String
    public let abstract: String
    
    public init(commandName: String, abstract: String) {
        self.commandName = commandName
        self.abstract = abstract
    }
}

/// Registry for managing available commands
@MainActor
public struct CommandRegistry {
    private static var registeredCommands: [String: any MistDemoCommand.Type] = [:]
    
    /// Register a command type with the registry
    public static func register<T: MistDemoCommand>(_ commandType: T.Type) {
        registeredCommands[commandType.commandName] = commandType
    }
    
    /// Get all registered command names
    public static var availableCommands: [String] {
        Array(registeredCommands.keys).sorted()
    }
    
    /// Create a command instance for the given name
    public static func createCommand(named name: String) throws -> any MistDemoCommand {
        guard let commandType = registeredCommands[name] else {
            throw MistDemoError.unknownCommand(name)
        }
        
        // Commands will be initialized with their own configuration parsing
        // This will be implemented per command based on Swift Configuration patterns
        fatalError("Command initialization to be implemented per command")
    }
}

/// Command line argument parser for Swift Configuration integration
public struct CommandLineParser {
    private let arguments: [String]
    
    public init(arguments: [String] = CommandLine.arguments) {
        self.arguments = arguments
    }
    
    /// Parse the command name from command line arguments
    public func parseCommandName() -> String? {
        // Skip the executable name (first argument)
        guard arguments.count > 1 else { return nil }
        let commandCandidate = arguments[1]
        
        // If it starts with '--', it's not a command but a global option
        if commandCandidate.hasPrefix("--") {
            return nil
        }
        
        return commandCandidate
    }
    
    /// Get all arguments after the command name for command-specific parsing
    public func commandArguments() -> [String] {
        guard arguments.count > 1 else { return [] }
        let commandName = arguments[1]
        
        // If first argument is an option, return all arguments for global parsing
        if commandName.hasPrefix("--") {
            return Array(arguments.dropFirst())
        }
        
        // Return arguments after command name
        return Array(arguments.dropFirst(2))
    }
    
    /// Check if help was requested
    public func isHelpRequested() -> Bool {
        arguments.contains { arg in
            arg == "--help" || arg == "-h" || arg == "help"
        }
    }
}