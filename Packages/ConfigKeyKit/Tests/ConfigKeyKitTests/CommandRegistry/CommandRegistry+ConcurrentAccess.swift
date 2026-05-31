//
//  CommandRegistry+ConcurrentAccess.swift
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
  @Suite("Concurrent Access")
  internal struct ConcurrentAccess {
    @Test("Concurrent registration")
    internal func concurrentRegistration() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          await registry.register(CommandRegistry.TestCommand.self)
        }
        group.addTask {
          await registry.register(CommandRegistry.AnotherCommand.self)
        }
      }

      let commands = await registry.availableCommands
      #expect(commands.count == 2)
    }

    @Test("Concurrent reads")
    internal func concurrentReads() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await registry.register(CommandRegistry.TestCommand.self)

      await withTaskGroup(of: Bool.self) { group in
        for _ in 0..<10 {
          group.addTask {
            await registry.isRegistered("test")
          }
        }

        var results: [Bool] = []
        for await result in group {
          results.append(result)
        }

        #expect(results.allSatisfy { $0 == true })
      }
    }

    @Test("Mixed concurrent operations")
    internal func mixedConcurrentOperations() async {
      let registry = ConfigKeyKit.CommandRegistry()

      await withTaskGroup(of: Void.self) { group in
        group.addTask {
          await registry.register(CommandRegistry.TestCommand.self)
        }
        group.addTask {
          _ = await registry.isRegistered("test")
        }
        group.addTask {
          _ = await registry.availableCommands
        }
      }

      let isRegistered = await registry.isRegistered("test")
      #expect(isRegistered == true)
    }
  }
}
