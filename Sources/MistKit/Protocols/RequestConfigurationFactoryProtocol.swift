public protocol RequestConfigurationFactoryProtocol {
  func configuration<RequestType: MKRequest>(
    from request: RequestType,
    withURLBuilder urlBuilder: MKURLBuilderProtocol
  ) throws -> RequestConfiguration
}
