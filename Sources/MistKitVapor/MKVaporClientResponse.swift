import MistKit
import Vapor

public struct MKVaporClientResponse: MKHttpResponse {
  public var body: Data? {
    response.body.map { Data(buffer: $0) }
  }

  public var status: Int {
    Int(response.status.code)
  }

  public var webAuthenticationToken: String? {
    response.headers["X-Apple-CloudKit-Web-Auth-Token"].first
  }

  let response: ClientResponse
}
