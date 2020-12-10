@testable import MistKit
import XCTest

struct MockHttpResponse: MKHttpResponse {
  let status: Int
  let webAuthenticationToken: String?
  let body: Data?
}

final class ResultTransformerTests: XCTestCase {
  func testData() {
    let exp = expectation(description: "Web Auth")
    let transformer = ResultTransformer()
    let expectedWAT = String.random(ofLength: 32)
    let expectedData: Data = .random()
    let result: Result<MKHttpResponse, Error> = .success(
      MockHttpResponse(
        status: .random(in: 0 ... .max),
        webAuthenticationToken: expectedWAT,
        body: expectedData
      )
    )
    let actual: Data?
    do {
      actual = try transformer.data(fromResult: result) { webAuthentication in
        XCTAssertEqual(webAuthentication, expectedWAT)
        exp.fulfill()
      }.get()
    } catch {
      XCTFail(error.localizedDescription)
      actual = nil
    }
    XCTAssertEqual(actual, expectedData)
    waitForExpectations(timeout: 1.0) { error in
      XCTAssertNil(error)
    }
  }

  func testNoData() {
    let exp = expectation(description: "Web Auth")
    let transformer = ResultTransformer()
    let expectedWAT = String.random(ofLength: 32)
    let expectedStatus: Int = .random(in: 0 ... .max)
    let result: Result<MKHttpResponse, Error> = .success(
      MockHttpResponse(
        status: expectedStatus,
        webAuthenticationToken: expectedWAT,
        body: nil
      )
    )
    let noError: Bool
    do {
      _ = try transformer.data(fromResult: result) { webAuthentication in
        XCTAssertEqual(webAuthentication, expectedWAT)
        exp.fulfill()
      }.get()
      noError = true
    } catch let MKError.noDataFromStatus(actualStatus) {
      XCTAssertEqual(actualStatus, expectedStatus)
      noError = false
    } catch {
      XCTFail(error.localizedDescription)
      noError = false
    }
    XCTAssertFalse(noError)
    waitForExpectations(timeout: 1.0) { error in
      XCTAssertNil(error)
    }
  }
}
