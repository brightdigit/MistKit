//
//  AuthTokenCommand+Routes.swift
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
  import AsyncAlgorithms
  import Foundation
  import HTTPTypes
  import Hummingbird
  import Logging
  import MistKit

  extension AuthTokenCommand {
    fileprivate struct CloudKitClientConfig: Encodable {
      let apiToken: String
      let containerIdentifier: String
    }

    internal func buildRouter(
      tokenChannel: AsyncChannel<String>,
      responseCompleteChannel: AsyncChannel<Void>
    ) throws -> Router<BasicRequestContext> {
      let router = Router(context: BasicRequestContext.self)
      router.middlewares.add(LogRequestsMiddleware(.info))

      let indexBytes = ByteBuffer(
        string: AuthTokenIndexHTML.content
      )
      let indexResponseBuilder: @Sendable () -> Response = {
        Response(
          status: .ok,
          headers: [
            .contentType: "text/html; charset=utf-8"
          ],
          body: ResponseBody { writer in
            try await writer.write(indexBytes)
            try await writer.finish(nil)
          }
        )
      }
      router.get("/") { _, _ -> Response in
        indexResponseBuilder()
      }
      router.get("/index.html") { _, _ -> Response in
        indexResponseBuilder()
      }

      let api = router.group("api")

      let configPayload = CloudKitClientConfig(
        apiToken: config.apiToken,
        containerIdentifier: config.containerIdentifier
      )
      let configData = try JSONEncoder().encode(
        configPayload
      )

      addConfigEndpoint(
        api: api, configData: configData
      )
      addAuthEndpoint(
        api: api,
        tokenChannel: tokenChannel,
        responseCompleteChannel: responseCompleteChannel
      )

      return router
    }

    internal func addConfigEndpoint(
      api: RouterGroup<BasicRequestContext>,
      configData: Data
    ) {
      api.get("config") { request, _ -> Response in
        let authority = request.head.authority ?? ""
        guard Self.isLoopbackAuthority(authority) else {
          return Response(status: .forbidden)
        }
        return Response(
          status: .ok,
          headers: [.contentType: "application/json"],
          body: ResponseBody { writer in
            try await writer.write(
              ByteBuffer(bytes: configData)
            )
            try await writer.finish(nil)
          }
        )
      }
    }

    internal func addAuthEndpoint(
      api: RouterGroup<BasicRequestContext>,
      tokenChannel: AsyncChannel<String>,
      responseCompleteChannel: AsyncChannel<Void>
    ) {
      api.post("authenticate") {
        request, context -> Response in
        let authRequest = try await request.decode(
          as: AuthRequest.self, context: context
        )
        await tokenChannel.send(authRequest.sessionToken)

        let response = AuthResponse(
          userRecordName: authRequest.userRecordName,
          cloudKitData: .init(
            user: nil, zones: [], error: nil
          ),
          message: "Authentication successful!"
        )

        let jsonData = try JSONEncoder().encode(response)

        Task {
          try await Task.sleep(nanoseconds: 200_000_000)
          await responseCompleteChannel.send(())
        }

        return Response(
          status: .ok,
          headers: [.contentType: "application/json"],
          body: ResponseBody { writer in
            try await writer.write(
              ByteBuffer(bytes: jsonData)
            )
            try await writer.finish(nil)
          }
        )
      }
    }
  }
#endif
