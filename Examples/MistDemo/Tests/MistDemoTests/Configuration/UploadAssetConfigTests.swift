//
//  UploadAssetConfigTests.swift
//  MistDemoTests
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
import Testing

@testable import MistDemoKit

@Suite("UploadAssetConfig Tests")
internal struct UploadAssetConfigTests {
  @Test("Memberwise init applies recordName=nil and json output by default")
  internal func defaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/tmp/photo.jpg",
      recordType: "Note",
      fieldName: "image"
    )

    #expect(config.file == "/tmp/photo.jpg")
    #expect(config.recordType == "Note")
    #expect(config.fieldName == "image")
    #expect(config.recordName == nil)
    #expect(config.output == .json)
  }

  @Test("Memberwise init accepts all custom values")
  internal func customValues() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/var/data/photo.png",
      recordType: "Photo",
      fieldName: "thumbnail",
      recordName: "rec-123",
      output: .yaml
    )

    #expect(config.file == "/var/data/photo.png")
    #expect(config.recordType == "Photo")
    #expect(config.fieldName == "thumbnail")
    #expect(config.recordName == "rec-123")
    #expect(config.output == .yaml)
  }

  @Test(
    "UploadAssetConfig output formats round-trip",
    arguments: [OutputFormat.json, .table, .csv, .yaml]
  )
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/tmp/photo.jpg",
      recordType: "Note",
      fieldName: "image",
      output: format
    )

    #expect(config.output == format)
  }

  @Test("UploadAssetConfig preserves a file path containing spaces")
  internal func pathWithSpaces() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = UploadAssetConfig(
      base: baseConfig,
      file: "/var/data/My Photos/img.jpg",
      recordType: "Note",
      fieldName: "image"
    )

    #expect(config.file == "/var/data/My Photos/img.jpg")
  }
}
