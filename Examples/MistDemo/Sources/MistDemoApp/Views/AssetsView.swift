//
//  AssetsView.swift
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

#if canImport(SwiftUI) && canImport(CloudKit)
  internal import MistDemoKit
  internal import SwiftUI

  /// View driving `assets/upload` and the composed `assets/rereference`
  /// against native CloudKit. Upload is a one-step `database.save(_:)`
  /// with a `CKAsset` payload; rereference fetches the source record,
  /// reuses its asset descriptor, and saves the target — surfaced via
  /// `CompositionDisclosure`.
  internal struct AssetsView: View {
    @Environment(CloudKitStore.self) private var service
    @State private var uploadTitle: String = "Asset demo"
    @State private var uploadIndex: Int64 = 0
    @State private var uploadFilePath: String = ""
    @State private var uploadResult: Note?
    @State private var uploadError: String?
    @State private var sourceRecord: String = ""
    @State private var assetField: String = "image"
    @State private var targetRecord: String = ""
    @State private var targetAssetField: String = ""
    @State private var rereferenceResult: RereferenceResult?
    @State private var rereferenceError: String?

    internal var body: some View {
      Form {
        uploadSection
        rereferenceSection
      }
      .formStyle(.grouped)
      .navigationTitle("Assets")
    }

    private var uploadSection: some View {
      Section {
        TextField("Note title", text: $uploadTitle)
        TextField(
          "Sort index", value: $uploadIndex, format: .number
        )
        TextField("Local file path", text: $uploadFilePath)
          .font(.body.monospaced())
        Button("Upload") { Task { await runUpload() } }
          .disabled(uploadTitle.isEmpty || uploadFilePath.isEmpty)
        if let uploadError {
          Text(uploadError).font(.callout).foregroundStyle(.red)
        }
        if let uploadResult {
          LabeledContent("Created", value: uploadResult.id)
        }
      } header: {
        Text("Upload — assets/upload")
      } footer: {
        Text(
          "Creates a Note with the file at the given path as its "
            + "`image` asset. Native CKAsset upload runs inline as part of "
            + "database.save(_:)."
        )
        .font(.caption)
      }
    }

    private var rereferenceSection: some View {
      Section {
        TextField("Source record name", text: $sourceRecord)
          .font(.body.monospaced())
        TextField("Asset field name", text: $assetField)
        TextField("Target record name", text: $targetRecord)
          .font(.body.monospaced())
        TextField(
          "Target asset field (optional)",
          text: $targetAssetField
        )
        Button("Rereference") { Task { await runRereference() } }
          .disabled(
            sourceRecord.isEmpty || targetRecord.isEmpty
              || assetField.isEmpty
          )
        if let rereferenceError {
          Text(rereferenceError).font(.callout).foregroundStyle(.red)
        }
        if let result = rereferenceResult {
          LabeledContent("Source", value: result.sourceRecordName)
          LabeledContent("Target", value: result.targetRecordName)
          LabeledContent("Field", value: result.targetAssetField)
        }
        CompositionDisclosure(
          restEndpoint: "assets/rereference",
          steps: [
            "database.record(for: source) — fetch source record",
            "Read source[assetField] as CKAsset",
            "database.record(for: target) — fetch target record",
            "target[targetAssetField] = asset; database.save(target)",
          ]
        )
      } header: {
        Text("Rereference — assets/rereference (composed)")
      }
    }

    private func runUpload() async {
      uploadError = nil
      uploadResult = nil
      let url = URL(fileURLWithPath: uploadFilePath)
      do {
        uploadResult = try await service.uploadAssetNote(
          title: uploadTitle,
          index: uploadIndex,
          fileURL: url
        )
      } catch {
        uploadError = error.localizedDescription
      }
    }

    private func runRereference() async {
      rereferenceError = nil
      rereferenceResult = nil
      do {
        rereferenceResult = try await service.rereferenceAsset(
          sourceRecordName: sourceRecord,
          assetField: assetField,
          targetRecordName: targetRecord,
          targetAssetField: targetAssetField.isEmpty ? nil : targetAssetField
        )
      } catch {
        rereferenceError = error.localizedDescription
      }
    }
  }
#endif
