//
//  CloudKitManagementService+ExportSchema.swift
//  MistKit
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
internal import MistKitManagementOpenAPI
internal import OpenAPIRuntime

extension CloudKitManagementService {
  /// The largest schema export collected (a schema export is plain text).
  internal static let maxResponseBytes = 32 * 1_024 * 1_024

  /// Collects a success body of at most ``maxResponseBytes`` as UTF-8 text.
  ///
  /// Collected chunk by chunk rather than with `Data(collecting:upTo:)`,
  /// whose over-limit error is private to OpenAPIRuntime and can't be told
  /// apart from a transport failure.
  private static func text(from body: HTTPBody) async throws -> String {
    let tooLarge = CloudKitManagementError.invalidResponse(
      reason: "schema export body exceeded \(maxResponseBytes) bytes"
    )
    if case .known(let length) = body.length, length > maxResponseBytes {
      throw tooLarge
    }
    var data = Data()
    for try await chunk in body {
      data.append(contentsOf: chunk)
      guard data.count <= maxResponseBytes else {
        throw tooLarge
      }
    }
    guard let text = String(data: data, encoding: .utf8) else {
      throw CloudKitManagementError.invalidResponse(reason: "schema export body is not UTF-8")
    }
    return text
  }

  /// Downloads an environment's schema as CloudKit Schema Language text.
  ///
  /// Sends the `exportSchema` operation from `management-openapi.yaml`:
  /// `GET /v1/database/teams/{teamId}/containers/{containerId}/environments/{environment}/schema/export`,
  /// which answers `200 text/plain`. This is the same text `cktool
  /// export-schema` writes to a `.ckdb` file.
  ///
  /// - Throws: ``CloudKitManagementError`` for an error response, or for a
  ///   success response that isn't UTF-8 text of at most 32 MiB; transport
  ///   errors propagate unchanged.
  public func exportSchemaText(environment: Environment) async throws -> String {
    let output: Operations.exportSchema.Output
    do {
      output = try await client.exportSchema(
        path: .init(
          teamId: teamIdentifier,
          containerId: containerIdentifier,
          environment: environment.managementEnvironment
        )
      )
    } catch let error as ClientError {
      throw await CloudKitManagementError.translating(error)
    }
    switch output {
    case .ok(let response):
      switch response.body {
      case .plainText(let body):
        return try await Self.text(from: body)
      }
    case .default(let statusCode, let response):
      switch response.body {
      case .json(let failure):
        throw CloudKitManagementError.requestFailed(
          ManagementRequestFailure(failure, statusCode: statusCode)
        )
      }
    }
  }

  /// Downloads and parses an environment's schema.
  ///
  /// The result carries the text as CloudKit returned it and the parsed
  /// ``CloudKitSchema``, whose fields report `QUERYABLE`, `SORTABLE` and
  /// `SEARCHABLE`.
  ///
  /// - Throws: ``CloudKitManagementError/invalidSchema(_:text:)`` when the
  ///   export isn't valid CloudKit Schema Language, plus everything
  ///   ``exportSchemaText(environment:)`` throws.
  public func exportSchema(environment: Environment) async throws -> ExportedSchema {
    let text = try await exportSchemaText(environment: environment)
    let schema: CloudKitSchema
    do {
      schema = try CloudKitSchema(parsing: text)
    } catch let parseError as SchemaParseError {
      throw CloudKitManagementError.invalidSchema(parseError, text: text)
    }
    return ExportedSchema(environment: environment, text: text, schema: schema)
  }
}
