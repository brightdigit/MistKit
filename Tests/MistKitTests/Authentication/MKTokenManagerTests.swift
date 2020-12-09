@testable import MistKit
import XCTest

class MockTokenStorage : MKTokenStorage {
  var webAuthenticationToken: String?
  
  
}

class MockAuthRedirect : MKAuthenticationRedirect {
  internal init(url: URL) {
    self.url = url
  }
  
  let url: URL
}
class MockTokenClient : MKTokenClient {
  internal init(onRequest: @escaping (MKAuthenticationRedirect?, (Result<String, Error>) -> Void) -> Void) {
    self.onRequest = onRequest
  }
  
  let onRequest : (MKAuthenticationRedirect?, (Result<String, Error>) -> Void) -> Void
  func request(_ request: MKAuthenticationRedirect?, _ callback: @escaping (Result<String, Error>) -> Void) {
    self.onRequest(request, callback)
  }
  
  
}
final class MKTokenManagerTests: XCTestCase {
  func testWebAuthenticationToken () {
    let storage = MockTokenStorage()
    let manager = MKTokenManager(storage: storage, client: nil)
    manager.webAuthenticationToken = UUID().uuidString
    XCTAssertEqual(manager.webAuthenticationToken, storage.webAuthenticationToken)
  }
  
  func testRequest () {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let storage = MockTokenStorage()
    let redirect = MockAuthRedirect(url: url)
    let exp = expectation(description: "")
    let result = UUID().uuidString
    let client = MockTokenClient { (actual, callback) in
      XCTAssertEqual(url, actual?.url)
      callback(.success(result))
    }
    let manager = MKTokenManager(storage: storage, client: client)
    manager.request(redirect) { (resActual) in
      guard case let .success(actual) = resActual else {
        XCTFail()
        exp.fulfill()
        return
      }
      XCTAssertEqual(result, actual)
      exp.fulfill()
    }
    waitForExpectations(timeout: 1.0) { (error) in
      XCTAssertNil(error)
    }
  }
}
