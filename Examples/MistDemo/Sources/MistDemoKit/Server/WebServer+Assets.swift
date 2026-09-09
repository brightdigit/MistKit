//
//  WebServer+Assets.swift
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

#if canImport(Hummingbird)
  internal import Foundation
  internal import Hummingbird
  internal import MistKit

  extension WebServer {
    /// `POST /api/assets/upload` and `POST /api/assets/rereference` — back
    /// the Notes panel's image generator (upload) and the rereference
    /// sub-section. CloudKit JS mode handles uploads inline through
    /// `saveRecords` and composes rereference client-side (fetch source →
    /// reuse descriptor → save target).
    internal func addAssetEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory

      api.post("assets/upload") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.UploadAsset.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let receipt = try await backend.webUploadAsset(
            data: body.data,
            recordType: body.recordType,
            fieldName: body.fieldName,
            recordName: body.recordName,
            zone: body.zone,
            database: body.database
          )
          return try WebJSON.encoder().encode(receipt)
        }
      }

      api.post("assets/rereference") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.RereferenceAsset.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let record = try await backend.webRereferenceAsset(
            sourceRecordName: body.sourceRecordName,
            assetField: body.assetField,
            targetRecordName: body.targetRecordName,
            targetAssetField: body.targetAssetField,
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.Records(records: [record])
          )
        }
      }
    }
  }
#endif
