import AsyncHTTPClient
import Foundation
import MistKit

public struct MKAsyncRequest: MKHttpRequest {
  public let client: HTTPClient
  public let url: URL
  public let data: Data?

  public func execute(
    _ callback: @escaping ((Result<any MKHttpResponse, Error>) -> Void)
  ) {
    var request: HTTPClient.Request

    do {
      request = try HTTPClient.Request(
        url: url,
        method: data == nil ? .GET : .POST
      )
    } catch {
      callback(.failure(error))
      return
    }

    if let data = data {
      request.body = .data(data)
      request.headers.add(name: "Content-Type", value: "application/json")
    }

    client.execute(
      request: request
    )
    .map(MKAsyncResponse.init)
    .whenComplete(callback)
  }
}
