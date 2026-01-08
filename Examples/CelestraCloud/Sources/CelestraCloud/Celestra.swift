//
//  Celestra.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
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
internal enum Celestra {
  internal static func main() async {
    let args = Array(CommandLine.arguments.dropFirst())

    guard let command = args.first else {
      printUsage()
      exit(1)
    }

    do {
      try await runCommand(command, args: Array(args.dropFirst()))
    } catch {
      print("Error: \(error)")
      exit(1)
    }
  }

  private static func runCommand(_ command: String, args: [String]) async throws {
    switch command {
    case "add-feed":
      try await AddFeedCommand.run(args: args)
    case "update":
      try await UpdateCommand.run()
    case "clear":
      try await ClearCommand.run(args: args)
    case "help", "--help", "-h":
      printUsage()
    default:
      print("Unknown command: \(command)")
      printUsage()
      exit(1)
    }
  }

  internal static func printUsage() {
    print(
      """
      celestra-cloud - RSS reader that syncs to CloudKit public database

      USAGE:
        celestra-cloud <command> [options]

      COMMANDS:
        add-feed <url>              Add a new RSS feed to CloudKit
        update [options]            Fetch and update RSS feeds
        clear --confirm             Delete all feeds and articles

      UPDATE OPTIONS:
        --update-delay <seconds>                    Delay between feeds (default: 2.0)
        --update-skip-robots-check                  Skip robots.txt checking
        --update-max-failures <count>               Skip feeds above failure threshold
        --update-min-popularity <count>             Only update popular feeds
        --update-last-attempted-before <iso8601>    Only update feeds before date

      CLOUDKIT OPTIONS (via environment variables):
        CLOUDKIT_CONTAINER_ID       CloudKit container identifier
        CLOUDKIT_KEY_ID             Server-to-Server key ID
        CLOUDKIT_PRIVATE_KEY_PATH   Path to .pem private key file
        CLOUDKIT_ENVIRONMENT        Either 'development' or 'production'

      EXAMPLES:
        celestra-cloud add-feed https://example.com/feed.xml
        celestra-cloud update --update-delay 3.0
        celestra-cloud clear --confirm
      """
    )
  }
}
