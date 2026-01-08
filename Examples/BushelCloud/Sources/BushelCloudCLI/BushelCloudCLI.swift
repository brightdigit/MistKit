//
//  BushelCloudCLI.swift
//  BushelCloud
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

@main
internal struct BushelCloudCLI {
  internal static func main() async throws {
    let args = Array(CommandLine.arguments.dropFirst())
    let command = args.first ?? "sync"

    switch command {
    case "sync":
      try await SyncCommand.run(args)
    case "status":
      try await StatusCommand.run(args)
    case "list":
      try await ListCommand.run(args)
    case "export":
      try await ExportCommand.run(args)
    case "clear":
      try await ClearCommand.run(args)
    default:
      print("Error: Unknown command '\(command)'")
      print("")
      print("Available commands:")
      print("  sync    - Sync data to CloudKit")
      print("  status  - Show CloudKit data source status")
      print("  list    - List CloudKit records")
      print("  export  - Export CloudKit data to JSON")
      print("  clear   - Clear all CloudKit records")
      Foundation.exit(1)
    }
  }
}
