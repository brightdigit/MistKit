//
//  UploadAssetPhase.swift
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

import Foundation
import MistKit

struct UploadAssetPhase: IntegrationPhase {
  typealias Input = Void
  typealias Output = AssetUploadReceipt

  let title = "Upload test asset"
  let emoji = "📤"
  let apiName = "uploadAssets"

  func apply(output: AssetUploadReceipt, to state: inout PhaseState) {
    state.assetReceipt = output
  }

  func run(input: Void, context: PhaseContext) async throws -> AssetUploadReceipt {
    print("\n\(emoji) \(title)")

    let testData = IntegrationTestData.generateTestImage(sizeKB: context.assetSizeKB)
    let sizeInMB = Double(testData.count) / 1_024 / 1_024

    if context.verbose {
      print("   Uploading \(testData.count) bytes (\(String(format: "%.2f", sizeInMB)) MB)...")
    }

    let receipt = try await context.service.uploadAssets(
      data: testData,
      recordType: IntegrationTestData.recordType,
      fieldName: "image"
    )

    print("✅ Uploaded asset: \(testData.count) bytes")

    if context.verbose {
      print("   Record: \(receipt.recordName)")
      print("   Field: \(receipt.fieldName)")
    }

    return receipt
  }
}
