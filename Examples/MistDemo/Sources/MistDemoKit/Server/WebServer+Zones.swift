//
//  WebServer+Zones.swift
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
    /// Register every zone route: `modify`, `list`, `lookup`, `changes`, and
    /// the follow-up `changes/zone` record-level route.
    internal func addZonesEndpoints(
      api: RouterGroup<BasicRequestContext>
    ) {
      addZonesModifyEndpoint(api: api)
      addZonesListEndpoint(api: api)
      addZonesLookupEndpoint(api: api)
      addZonesChangesEndpoint(api: api)
      addZoneRecordChangesEndpoint(api: api)
    }

    /// `POST /api/zones/modify` — create and/or delete zones in one batch,
    /// backing the demo's MistKit-mode "Create Zone" / "Delete Zone" buttons.
    /// CloudKit JS mode hits the browser SDK directly; this is the
    /// server-side counterpart.
    private func addZonesModifyEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("zones/modify") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ModifyZones.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let zones = try await backend.webModifyZones(
            create: body.create.map(\.zoneName),
            delete: body.delete.map(\.zoneName),
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.Zones(zones: zones)
          )
        }
      }
    }

    /// `POST /api/zones/list` — every zone in the target database.
    private func addZonesListEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("zones/list") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ListZones.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let zones = try await backend.webListZones(database: body.database)
          return try WebJSON.encoder().encode(
            WebResponse.Zones(zones: zones)
          )
        }
      }
    }

    /// `POST /api/zones/lookup` — resolve specific zones by name.
    private func addZonesLookupEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("zones/lookup") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.LookupZones.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let zones = try await backend.webLookupZones(
            zoneNames: body.zoneNames,
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.Zones(zones: zones)
          )
        }
      }
    }

    /// `POST /api/zones/changes` — database-level zone changes since an
    /// optional continuation `syncToken`. Backed by `changes/database`, the
    /// current replacement for the deprecated `zones/changes` operation;
    /// reports *which* zones changed. Follow up with `changes/zone`
    /// (``addZoneRecordChangesEndpoint(api:)``) to fetch the record changes
    /// inside them.
    private func addZonesChangesEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("zones/changes") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ZoneChanges.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let result = try await backend.webZoneChanges(
            syncToken: body.syncToken,
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.ZoneChanges(from: result)
          )
        }
      }
    }

    /// `POST /api/changes/zone` — record changes within one or more zones,
    /// mirroring CloudKit Web Services `changes/zone`. Each zone paginates
    /// independently, carrying its own `syncToken` and `moreComing` flag.
    private func addZoneRecordChangesEndpoint(
      api: RouterGroup<BasicRequestContext>
    ) {
      let tokenStore = self.tokenStore
      let backendFactory = self.backendFactory
      api.post("changes/zone") { request, context -> Response in
        guard let token = await tokenStore.currentToken else {
          return Response(status: .unauthorized)
        }
        let body = try await request.decode(
          as: WebRequests.ZoneRecordChanges.self, context: context
        )
        return try await Self.runOperation { () -> Data in
          let backend = try backendFactory.make(token)
          let zones = body.zones.map {
            ZoneChangesRequest(
              zoneID: ZoneID(zoneName: $0.zoneName),
              syncToken: $0.syncToken
            )
          }
          let result = try await backend.webRecordZoneChanges(
            zones: zones,
            database: body.database
          )
          return try WebJSON.encoder().encode(
            WebResponse.ZoneRecordChanges(from: result)
          )
        }
      }
    }
  }
#endif
