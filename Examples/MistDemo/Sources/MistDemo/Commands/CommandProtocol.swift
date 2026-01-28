//
//  CommandProtocol.swift
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

import ArgumentParser
import Foundation

/// Protocol for MistDemo commands with shared configuration loading
protocol MistDemoCommand: AsyncParsableCommand {
  /// Global options shared across all commands
  var globalOptions: GlobalOptions { get set }

  /// Execute the command with loaded configuration
  func execute(with config: MistDemoConfig) async throws
}

extension MistDemoCommand {
  /// Default run implementation that loads configuration and executes the command
  mutating func run() async throws {
    // Load configuration from all sources
    let config = try await globalOptions.loadConfiguration()

    // Execute the command with the loaded configuration
    try await execute(with: config)
  }
}
