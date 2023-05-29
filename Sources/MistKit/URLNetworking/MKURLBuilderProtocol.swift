import Foundation

public protocol MKURLBuilderProtocol {
  var tokenManager: (any MKTokenManagerProtocol)? { get }
  func url(withPathComponents pathComponents: [String]) throws -> URL
}
