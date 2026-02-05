//
//  CommandRegistry.swift
//  ConfigKeyKit
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

/// Actor-based registry for managing available commands
public actor CommandRegistry {
    private var registeredCommands: [String: any Command.Type] = [:]
    private var commandMetadata: [String: CommandMetadata] = [:]

    /// Metadata about a command
    public struct CommandMetadata: Sendable {
        public let commandName: String
        public let abstract: String
        public let helpText: String
    }

    /// Shared instance
    public static let shared = CommandRegistry()

    // Internal initializer for testability - allows tests to create isolated instances
    internal init() {}

    /// Register a command type with the registry
    public func register<T: Command>(_ commandType: T.Type) {
        registeredCommands[T.commandName] = commandType
        commandMetadata[T.commandName] = CommandMetadata(
            commandName: T.commandName,
            abstract: T.abstract,
            helpText: T.helpText
        )
    }

    /// Get all registered command names
    public var availableCommands: [String] {
        Array(registeredCommands.keys).sorted()
    }

    /// Get command metadata
    public func metadata(for name: String) -> CommandMetadata? {
        commandMetadata[name]
    }

    /// Get command type for the given name
    public func commandType(named name: String) -> (any Command.Type)? {
        return registeredCommands[name]
    }

    /// Create a command instance dynamically with automatic config parsing
    public func createCommand(named name: String) async throws -> any Command {
        guard let commandType = registeredCommands[name] else {
            throw CommandRegistryError.unknownCommand(name)
        }

        return try await commandType.createInstance()
    }

    /// Check if a command is registered
    public func isRegistered(_ name: String) -> Bool {
        return registeredCommands[name] != nil
    }
}
