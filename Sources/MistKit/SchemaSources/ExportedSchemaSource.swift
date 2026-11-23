//
//  ExportedSchemaSource.swift
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

/// The schema CloudKit's Management API exports for an environment
/// (``CloudKitManagementService/exportSchema(environment:)``).
///
/// It's the only source with every index option and grant. It never asks for
/// a reload; load it again to see changes made in CloudKit Console.
public struct ExportedSchemaSource: SchemaSource {
  /// The service the export is sent through.
  public let service: CloudKitManagementService
  /// The environment whose schema is exported.
  public let environment: Environment

  /// Creates a source for one environment's schema.
  public init(service: CloudKitManagementService, environment: Environment) {
    self.service = service
    self.environment = environment
  }

  /// Exports and parses the schema.
  ///
  /// - Throws: Everything ``CloudKitManagementService/exportSchema(environment:)``
  ///   throws.
  public func loadSchema() async throws -> CloudKitSchema {
    try await service.exportSchema(environment: environment).schema
  }
}
