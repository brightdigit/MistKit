import Foundation

public struct RequestConfigurationFactory: RequestConfigurationFactoryProtocol {
  public let encoder: MKEncoder = JSONEncoder()

  public func configuration<RequestType>(
    from request: RequestType,
    withURLBuilder urlBuilder: MKURLBuilder
  ) throws -> RequestConfiguration where RequestType: MKRequest {
    let url: URL = try urlBuilder.url(withPathComponents: request.relativePath)
    let data: Data? = try encoder.optionalData(from: request.data)
    return RequestConfiguration(url: url, data: data)
  }
}
