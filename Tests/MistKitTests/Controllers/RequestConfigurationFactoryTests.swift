@testable import MistKit
import XCTest

public struct MockURLBuilder : MKURLBuilderProtocol {
  let url : URL
  
  public func url(withPathComponents pathComponents: [String]) throws -> URL {
    return url
  }
  
  public let tokenManager: MKTokenManagerProtocol? = nil
}
public struct MockResponse : MKDecodable {
  
}

public struct MockData : MKEncodable, MKDecodable {
  let value : UUID
}
public struct MockRequest : MKRequest {
  
  public typealias Response = MockResponse
  
  public typealias Data = MockData
  
  public let data : MockData

  public let database: MistKit.MKDatabaseType = .private

  public let subpath = [String]()
  
}

final class RequestConfigurationFactoryTests: XCTestCase {
  func testConfiguration () {
    let factory = RequestConfigurationFactory()
    let value = UUID()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let configuration = try! factory.configuration(from: MockRequest(data: MockData(value: value)), withURLBuilder: MockURLBuilder(url: url))
    let decoder = JSONDecoder()
    let actual = try! decoder.decode(MockData.self, from: configuration.data!)
    XCTAssertEqual(actual.value, value)
    XCTAssertEqual(configuration.url, url)
    
  }
}
