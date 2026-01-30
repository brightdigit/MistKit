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

/// Generic registry for managing available commands
@MainActor
public struct CommandRegistry {
    private static var registeredCommands: [String: any Command.Type] = [:]
    
    /// Register a command type with the registry
    public static func register<T: Command>(_ commandType: T.Type) {
        registeredCommands[commandType.commandName] = commandType
    }
    
    /// Get all registered command names
    public static var availableCommands: [String] {
        Array(registeredCommands.keys).sorted()
    }
    
    /// Get command type for the given name
    public static func commandType(named name: String) -> (any Command.Type)? {
        return registeredCommands[name]
    }
    
    /// Check if a command is registered
    public static func isRegistered(_ name: String) -> Bool {
        return registeredCommands[name] != nil
    }
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