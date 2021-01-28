@testable import MistKit
import XCTest
final class MKStaticTokenManagerTests: XCTestCase {
  func testNoClientWithTokenString () {
    let token = String.random(ofLength: 32)
    let manager = MKStaticTokenManager(token: token, client: nil)
    XCTAssertEqual( manager.webAuthenticationToken, token)
    let url = URL.random()
    let testExp = expectation(description: "test")
    manager.request(MockAuthRedirect(url: url)) { (result) in
      switch result {
      case .failure(let error):
        guard let mkError = error as? MKError else {
          XCTFail()
          break
        }
        guard case let .authenticationRequired(redirect) = mkError else {
          XCTFail()
          break
        }
        XCTAssertEqual(redirect.url, url)
        
      default:
        XCTFail()
      }
      testExp.fulfill()
    }
    waitForExpectations(timeout: 1.0) { (error) in
      XCTAssertNil(error)
    }
  }
  
  func testWClientWithTokenString () {
    let requestExp = expectation(description: "request")
    let clientExp = expectation(description: "client")
    let token = String.random(ofLength: 32)
    let url = URL.random()
    let success = String.random(ofLength: 32)
    let client = MockTokenClient { (redirect, callback) in
      XCTAssertEqual(redirect?.url, url)
      callback(.success(success))
      clientExp.fulfill()
    }
    let manager = MKStaticTokenManager(token: token, client: client)
    XCTAssertEqual( manager.webAuthenticationToken, token)
    manager.request(MockAuthRedirect(url: url)) { (result) in
      guard case let .success(actualToken) = result else {
        XCTFail()
        requestExp.fulfill()
        return
        
      }
      XCTAssertEqual(actualToken, success)
      requestExp.fulfill()
    }
    waitForExpectations(timeout: 1.0) { (error) in
      XCTAssertNil(error)
    }
  }
}
