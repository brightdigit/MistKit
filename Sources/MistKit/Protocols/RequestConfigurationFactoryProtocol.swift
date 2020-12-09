public protocol RequestConfigurationFactoryProtocol {
  func configuration<RequestType: MKRequest>(
    from request: RequestType,
    withURLBuilder urlBuilder: MKURLBuilder
  ) throws -> RequestConfiguration
}
