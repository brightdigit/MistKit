//
//  CloudKitManagementService+Send.swift
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
internal import HTTPTypes
internal import OpenAPIRuntime

extension CloudKitManagementService {
  /// The largest response body collected (a schema export is plain text).
  private static let maxResponseBytes = 32 * 1_024 * 1_024

  /// Sends `request` with the management token and returns the body of a
  /// 2xx response.
  internal func send(_ request: ManagementRequest) async throws -> Data {
    let httpRequest = request.httpRequest(managementToken: managementToken)
    let (response, body) = try await transport.send(
      httpRequest,
      body: nil,
      baseURL: Self.baseURL,
      operationID: request.operationID
    )
    let data: Data =
      if let body {
        try await Data(collecting: body, upTo: Self.maxResponseBytes)
      } else {
        Data()
      }
    guard response.status.kind == .successful else {
      throw CloudKitManagementError(statusCode: response.status.code, body: data)
    }
    return data
  }
}
