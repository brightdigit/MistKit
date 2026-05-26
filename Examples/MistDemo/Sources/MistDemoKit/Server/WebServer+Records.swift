//
//  WebServer+Records.swift
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
    /// Register the record routes wired to landed MistKit wrappers:
    /// `lookup` and `changes`. (`query`/`create`/`update`/`delete` are
    /// registered elsewhere; `resolve` stays a pending stub — see #41.)
    internal func addRecordsEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      addRecordsLookupEndpoint(api: api)
      addRecordsChangesEndpoint(api: api)
    }

    /// `POST /api/records/lookup` — fetch specific records by name, mirroring
    /// CloudKit JS mode's `fetchRecords`.
    private func addRecordsLookupEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/lookup") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.Lookup.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let records = try await backend.webLookupRecords(
            recordNames: body.recordNames,
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.Records(records: records)
          )
        }
      }
    }

    /// `POST /api/records/changes` — record changes in a zone since an
    /// optional continuation `syncToken`.
    private func addRecordsChangesEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("records/changes") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.RecordChanges.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let result = try await backend.webRecordChanges(
            zoneName: body.zoneName,
            syncToken: body.syncToken,
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.RecordChanges(from: result)
          )
        }
      }
    }
  }
#endif
