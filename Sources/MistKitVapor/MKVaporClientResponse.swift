import MistKit
import Vapor

public struct MKVaporClientResponse: MKHttpResponse {
  public var body: Data? {
    return response.body.map { Data(buffer: $0) }
  }

  public var status: Int {
    return Int(response.status.code)
  }

  public var webAuthenticationToken: String? {
    return response.headers["X-Apple-CloudKit-Web-Auth-Token"].first
  }

  let response: ClientResponse
}
