//
//  ProbeEncryptedCommand.swift
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

internal import Foundation
internal import MistKit

/// Characterizes encrypted-field behavior for the current web-auth user.
///
/// Runs the live protocol from issue #392 as independent steps — every step
/// reports its own outcome instead of aborting the run, so an Advanced Data
/// Protection account can be compared step-for-step with a standard one.
public struct ProbeEncryptedCommand: MistDemoCommand {
  /// The configuration type.
  public typealias Config = ProbeEncryptedConfig
  /// The command name.
  public static let commandName = "probe-encrypted"
  /// The command abstract.
  public static let abstract =
    "Probe encrypted-field reads/writes for the signed-in user (issue #392)"
  /// The command help text.
  public static let helpText = """
    PROBE-ENCRYPTED - Characterize encrypted fields for one web-auth user

    Writes a record with an ENCRYPTED STRING field ("secret"), a plain
    sibling record, and an asset; then reads everything back through
    records/lookup, records/query and records/changes and downloads the
    asset. Every step reports independently — nothing aborts the run — so
    the same command can be run under standard data protection and under
    Advanced Data Protection (ADP) and the outputs compared.

    Probe records persist between runs (same names on every run), so a
    record written under standard protection can be read back after the
    account turns ADP on. Pass --cleanup on the final run.

    USAGE:
      mistdemo probe-encrypted [options]

    OPTIONS:
      --record-name <name>    Base record name (default: mistkit-enc-probe)
      --zone-name <name>      Custom zone (default: the database default zone)
      --zone-owner <owner>    Zone owner record name (shared zones)
      --database <type>       private (default) or shared
      --asset-size <kb>       Probe asset size in KB (default: 100)
      --skip-write            Only read back an earlier run's records
      --cleanup               Delete the probe records at the end
      --verbose               Print HTTP request/response traces

    EXAMPLES:
      mistdemo probe-encrypted --verbose                 # standard account: B0/C4
      mistdemo probe-encrypted --skip-write --verbose    # same account, after ADP
      mistdemo probe-encrypted --cleanup                 # write + read + delete

    NOTES:
      - The plain sibling record is named <record-name>-plain.
      - records/lookup is skipped for custom zones (no zoneID parameter).
      - Requires CLOUDKIT_API_TOKEN and CLOUDKIT_WEB_AUTH_TOKEN
        (capture with `mistdemo auth-token`).
      - Requires "secret" ENCRYPTED STRING on Note in the deployed schema
        (see Examples/MistDemo/schema.ckdb).
      - Capture the output verbatim; the results feed issue #392.
    """

  private let config: ProbeEncryptedConfig

  /// Creates a new instance.
  public init(config: ProbeEncryptedConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    if config.verbose {
      MistDemoLoggingBootstrap.bootstrapOnce()
    }
    let service = try MistKitClientFactory.create(for: config.base)
    var runner = ProbeEncryptedRunner(service: service, config: config)
    await runner.run()
  }
}
