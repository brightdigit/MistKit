import AsyncHTTPClient
import Foundation
import MistKit

public struct MKAsyncRequest: MKHttpRequest {
  let client: HTTPClient
  let url: URL
  let data: Data?

  public func execute(_ callback: @escaping ((Result<MKHttpResponse, Error>) -> Void)) {
    //    var clientRequest = HTTPClient.Request(url: url)

    //    return MKVaporClientRequest(client: client, request: clientRequest)

    var request: HTTPClient.Request
    do {
      request = try HTTPClient.Request(url: url, method: data == nil ? .GET : .POST)
    } catch {
      callback(.failure(error))
      return
    }
    if let data = data {
      request.body = .data(data)
      request.headers.add(name: "Content-Type", value: "application/json")
      // request.headers.add(name: .contentType, value: "application/json")
    }
    client.execute(request: request).map(MKAsyncResponse.init).whenComplete(callback)
  }
}
