@testable import MistKit
import XCTest

public struct MockURLBuilder: MKURLBuilderProtocol {
  let url: URL

  public func url(withPathComponents _: [String]) throws -> URL {
    url
  }

  public let tokenManager: MKTokenManagerProtocol? = nil
}

public struct MockResponse: MKDecodable {}

public struct MockData: MKEncodable, MKDecodable {
  let value: UUID
}

public struct MockRequest: MKRequest {
  public typealias Response = MockResponse

  public typealias Data = MockData

  public let data: MockData

  public let database: MistKit.MKDatabaseType = .private

  public let subpath = [String]()
}

final class RequestConfigurationFactoryTests: XCTestCase {
  public func testConfiguration() {
    let factory = RequestConfigurationFactory()
    let value = UUID()
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString
    )
    let decoder = JSONDecoder()
    let configuration: RequestConfiguration
    let actual: MockData
    do {
      configuration = try factory.configuration(
        from: MockRequest(data: MockData(value: value)),
        withURLBuilder: MockURLBuilder(url: url)
      )
      guard let data = configuration.data else {
        XCTFail()
        return
      }
      actual = try decoder.decode(MockData.self, from: data)
    } catch {
      XCTFail(error.localizedDescription)
      return
    }
    XCTAssertEqual(actual.value, value)
    XCTAssertEqual(configuration.url, url)
  }
}
