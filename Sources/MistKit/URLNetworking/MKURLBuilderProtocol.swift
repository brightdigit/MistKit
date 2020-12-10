import Foundation

public protocol MKURLBuilderProtocol {
  var tokenManager: MKTokenManagerProtocol? { get }
  func url(withPathComponents pathComponents: [String]) throws -> URL
}
