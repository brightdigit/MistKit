//
//  CommandLineParser.swift
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