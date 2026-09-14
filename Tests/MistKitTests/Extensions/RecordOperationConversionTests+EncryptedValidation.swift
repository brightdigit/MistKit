//
//  RecordOperationConversionTests+EncryptedValidation.swift
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
internal import MistKitOpenAPI
internal import Testing

@testable import MistKit

/// Client-side rejection of encrypted-field writes CloudKit cannot honor.
extension RecordOperationConversionTests {
  @Suite("Encrypted Field Validation", .disabled(if: Platform.isWindowsSwift62))
  internal struct EncryptedFieldValidation {
    @Test("validateEncryptedFields rejects public database writes")
    internal func validateRejectsPublicDatabase() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let operation = RecordOperation(
          operationType: .create,
          recordType: "TestRecord",
          recordName: "enc-1",
          fields: ["secret": .string(.value("hidden"))],
          encryptedFields: ["secret"]
        )

        #expect(throws: CloudKitError.self) {
          try operation.validateEncryptedFields(for: .public(.prefers(.serverToServer)))
        }
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("validateEncryptedFields rejects reference and asset fields")
    internal func validateRejectsReferenceAndAsset() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let referenceOp = RecordOperation(
          operationType: .create,
          recordType: "TestRecord",
          recordName: "enc-ref",
          fields: [
            "link": .reference(
              .value(Reference(recordName: "other", action: Reference.Action.none))
            )
          ],
          encryptedFields: ["link"]
        )
        #expect(throws: CloudKitError.self) {
          try referenceOp.validateEncryptedFields(for: .private)
        }

        let assetOp = RecordOperation(
          operationType: .create,
          recordType: "TestRecord",
          recordName: "enc-asset",
          fields: [
            "file": .asset(.value(Asset(fileChecksum: "abc", size: 1, referenceChecksum: "def")))
          ],
          encryptedFields: ["file"]
        )
        #expect(throws: CloudKitError.self) {
          try assetOp.validateEncryptedFields(for: .private)
        }
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    /// A *list* of references or assets is rejected for the same reason a single one is.
    /// Before #481 these arrived as `.list([...])`, which the validator waved through
    /// without inspecting its members; since lists became homogeneous a list of
    /// references is exactly `.reference(.list)`, so the arity-free pattern catches it.
    @Test("validateEncryptedFields rejects lists of references and assets")
    internal func validateRejectsReferenceAndAssetLists() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let referenceListOp = RecordOperation(
          operationType: .create,
          recordType: "TestRecord",
          recordName: "enc-ref-list",
          fields: [
            "links": .reference(
              .list([
                Reference(recordName: "a", action: Reference.Action.none),
                Reference(recordName: "b", action: Reference.Action.none),
              ])
            )
          ],
          encryptedFields: ["links"]
        )
        #expect(throws: CloudKitError.self) {
          try referenceListOp.validateEncryptedFields(for: .private)
        }

        let assetListOp = RecordOperation(
          operationType: .create,
          recordType: "TestRecord",
          recordName: "enc-asset-list",
          fields: [
            "files": .asset(
              .list([Asset(fileChecksum: "abc", size: 1, referenceChecksum: "def")])
            )
          ],
          encryptedFields: ["files"]
        )
        #expect(throws: CloudKitError.self) {
          try assetListOp.validateEncryptedFields(for: .private)
        }
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    /// `LOCATION` is the third scalar the request conversion leaves untagged, so an
    /// encrypted location has to pick up its `type` from `explicitType(for:)`.
    @Test("Conversion tags an encrypted location with LOCATION")
    internal func conversionTagsEncryptedLocation() throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let operation = RecordOperation(
          operationType: .create,
          recordType: "TestRecord",
          recordName: "enc-loc",
          fields: ["spot": .location(.value(Location(latitude: 1.5, longitude: -2.5)))],
          encryptedFields: ["spot"]
        )

        let converted = try Components.Schemas.RecordOperation(from: operation)
        let fields = converted.record?.fields?.additionalProperties
        #expect(fields?["spot"]?.isEncrypted == true)
        #expect(fields?["spot"]?._type == .LOCATION)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }
  }
}
