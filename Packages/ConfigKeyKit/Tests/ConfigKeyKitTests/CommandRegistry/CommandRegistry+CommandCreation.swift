//
//  CommandRegistry+CommandCreation.swift
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

import Testing

@testable import ConfigKeyKit

extension CommandRegistry {
  @Suite("Command Creation")
  internal struct CommandCreation {
    @Test("Create command instance")
    internal func createCommandInstance() async throws {
      let registry = ConfigKeyKit.CommandRegistry()

      await registry.register(CommandRegistry.TestCommand.self)

      let command = try await registry.createCommand(named: "test")

      #expect(command is CommandRegistry.TestCommand)
    }

    @Test("Create command instance throws for unknown command")
    internal func createCommandInstanceThrows() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await #expect(throws: CommandRegistryError.self) {
        try await registry.createCommand(named: "unknown")
      }
    }
  }
}
