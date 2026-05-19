//
//  ValidateCommand.swift
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

/// Command that validates the local CloudKit credential configuration and
/// optionally exercises a live API round-trip.
public struct ValidateCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = ValidateConfig
  /// The command name.
  public static let commandName = "validate"
  /// The command abstract.
  public static let abstract = "Validate CloudKit credentials and reachability"
  /// The command help text.
  public static let helpText = """
    VALIDATE - Validate CloudKit credentials and reachability

    USAGE:
      mistdemo validate [options]

    OPTIONS:
      --validate.skip-network    Only parse credentials; skip network call.
      --validate.test-query      Also run a minimal listZones query.
      --output-format <format>   Output format (json, table, csv, yaml).

    EXIT CODES:
      0  Validation succeeded.
      1  One or more checks failed; see structured `errors` in output.

    NOTES:
      - `fetchCaller` (the network check) requires API + web-auth
        credentials. With server-to-server only, the network check is
        skipped automatically.
      - With --validate.skip-network, only the parse-time check runs.
    """

  private let config: ValidateConfig

  /// Creates a new instance.
  public init(config: ValidateConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    var errors: [String] = []
    let service = makeService(into: &errors)
    let userInfo = await fetchCallerIfPossible(
      service: service,
      errors: &errors
    )
    let zonesFound = await runTestQueryIfRequested(
      service: service,
      errors: &errors
    )

    let result = ValidationResult(
      credentialsValid: service != nil,
      webAuthConfigured: config.base.hasUserContextCredentials,
      serverToServerConfigured: config.base.hasServerToServerCredentials,
      userInfo: userInfo,
      zonesFound: zonesFound,
      errors: errors
    )
    try await emit(result)

    if !errors.isEmpty {
      throw ValidateError.missingCredentials(
        errors.joined(separator: "; ")
      )
    }
  }

  /// Emit the validation result. JSON output is written through
  /// `FileHandle.standardOutput` directly so callers piping the output
  /// still see structured JSON even when this command throws afterwards
  /// (Swift's `print()` is fully buffered when stdout is not a TTY, and
  /// the fatal-error path that handles the throw doesn't flush the buffer).
  private func emit(_ result: ValidationResult) async throws {
    guard config.output == .json else {
      try await outputResult(result, format: config.output)
      return
    }
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(result)
    FileHandle.standardOutput.write(data)
    FileHandle.standardOutput.write(Data("\n".utf8))
  }

  private func makeService(into errors: inout [String]) -> CloudKitService? {
    do {
      return try MistKitClientFactory.create(for: config.base)
    } catch {
      errors.append(error.localizedDescription)
      return nil
    }
  }

  private func fetchCallerIfPossible(
    service: CloudKitService?,
    errors: inout [String]
  ) async -> UserInfo? {
    guard let service,
      !config.skipNetwork,
      config.base.hasUserContextCredentials
    else {
      return nil
    }
    do {
      return try await service.fetchCaller()
    } catch {
      errors.append("fetchCaller failed: \(error.localizedDescription)")
      return nil
    }
  }

  private func runTestQueryIfRequested(
    service: CloudKitService?,
    errors: inout [String]
  ) async -> Int? {
    guard let service, config.testQuery else {
      return nil
    }
    do {
      let zones = try await service.listZones(database: config.base.database)
      return zones.count
    } catch {
      errors.append(
        "Test query (listZones) failed: \(error.localizedDescription)"
      )
      return nil
    }
  }
}
