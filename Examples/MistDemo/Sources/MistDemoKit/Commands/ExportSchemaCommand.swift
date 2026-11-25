//
//  ExportSchemaCommand.swift
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

/// Exports a container's schema through the CloudKit Management API.
///
/// This is the live check for `management-openapi.yaml`: it sends the
/// generated `exportSchema` request with a management token.
public struct ExportSchemaCommand: MistDemoCommand {
  /// The command's configuration type.
  public typealias Config = ExportSchemaConfig
  /// The command name on the command line.
  public static let commandName = "export-schema"
  /// A one-line description.
  public static let abstract = "Export the container's schema through the CloudKit Management API"
  /// The full help text.
  public static let helpText = """
    EXPORT-SCHEMA - Export the container's schema (CloudKit Management API)

    USAGE:
      mistdemo export-schema [options]

    OPTIONS:
      --environment <env>        development (default) | production
      --team-id <id>             Team that owns the container (DEVELOPMENT_TEAM)
      --management-token <tok>   CloudKit Console → Settings token
      --raw                      Print the schema text exactly as exported

    EXAMPLES:
      mistdemo export-schema --raw
      mistdemo export-schema --environment production

    NOTES:
      - Uses https://api.icloud.apple.com, not api.apple-cloudkit.com, and only
        the management token: no API token or server-to-server key.
      - On an error response, every RequestError field is printed.
      - Set the token as CLOUDKIT_MANAGEMENT_TOKEN (environment or .env) rather
        than --management-token, so it stays out of shell history.
    """

  private let config: ExportSchemaConfig

  /// Creates the command.
  public init(config: ExportSchemaConfig) {
    self.config = config
  }

  private static func printSummary(_ exported: ExportedSchema) {
    print("Environment: \(exported.environment)")
    print("Roles: \(exported.schema.roles.joined(separator: ", "))")
    for recordType in exported.schema.recordTypes {
      print("\nRECORD TYPE \(recordType.name)")
      for field in recordType.fields {
        let flags = [
          field.isQueryable ? "QUERYABLE" : nil,
          field.isSortable ? "SORTABLE" : nil,
          field.isSearchable ? "SEARCHABLE" : nil,
        ]
        .compactMap(\.self)
        print("  \(field.name) \(field.type.schemaText) \(flags.joined(separator: " "))")
      }
      for grant in recordType.grants {
        print("  \(grant)")
      }
    }
  }

  private static func printDetails(of error: CloudKitManagementError) {
    var lines: [String] = []
    switch error {
    case .requestFailed(let failure):
      lines = [
        "requestFailed",
        "  statusCode: \(failure.statusCode)",
        "  code: \(failure.code)",
        "  message: \(failure.message)",
        "  reason: \(failure.reason)",
        "  detailedMessage: \(failure.detailedMessage ?? "nil")",
        "  requestUUID: \(failure.requestUUID ?? "nil")",
        "  retryAfterSeconds: \(failure.retryAfterSeconds.map(String.init) ?? "nil")",
      ]
    case .httpError(let statusCode, let body):
      lines = ["httpError", "  statusCode: \(statusCode)", "  body: \(body ?? "nil")"]
    case .invalidResponse(let reason):
      lines = ["invalidResponse", "  reason: \(reason)"]
    case .invalidSchema(let parseError, let text):
      lines = [
        "invalidSchema",
        "  \(parseError.errorDescription ?? "\(parseError)")",
        "  text:\n\(text)",
      ]
    }
    FileHandle.standardError.write(Data((lines.joined(separator: "\n") + "\n").utf8))
  }

  /// Runs the export and prints the result.
  public func execute() async throws {
    guard let token = config.managementToken, !token.isEmpty else {
      throw ExportSchemaError.missingManagementToken
    }
    guard let teamID = config.teamID, !teamID.isEmpty else {
      throw ExportSchemaError.missingTeamID
    }
    let service = CloudKitManagementService(
      teamIdentifier: teamID,
      containerIdentifier: config.base.containerIdentifier,
      managementToken: ManagementToken(token)
    )
    let environment = config.base.environment
    do {
      if config.raw {
        print(try await service.exportSchemaText(environment: environment), terminator: "")
      } else {
        Self.printSummary(try await service.exportSchema(environment: environment))
      }
    } catch let error as CloudKitManagementError {
      Self.printDetails(of: error)
      throw error
    }
  }
}
