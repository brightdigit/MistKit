@testable import MistKit
import XCTest

public struct MockError<T>: Error {
  public let value: T
}

struct MockAuthenticationRedirect: MKAuthenticationRedirect {
  let url: URL
}

final class MKServerResponseTests: XCTestCase {
  public func testInitAttemptRecoveryFromURL() {
    let expected = URL.random()
    let error: Error = MKError.authenticationRequired(
      MockAuthenticationRedirect(url: expected)
    )
    let serverResponse = try? MKServerResponse<UUID>(attemptRecoveryFrom: error)
    guard case let .failure(actual) = serverResponse else {
      XCTFail()
      return
    }
    XCTAssertEqual(expected, actual)
  }

  public func testInitAttemptRecoveryFromFailure() {
    let expected = UUID()
    let error = MockError(value: expected)
    do {
      _ = try MKServerResponse<UUID>(attemptRecoveryFrom: error)
    } catch let mockError as MockError<UUID> {
      XCTAssertEqual(mockError.value, expected)
      return
    } catch {
      XCTFail(error.localizedDescription)
      return
    }
    XCTFail()
  }

  public func testInitFromResultSuccess() {
    let expected = UUID()
    let result: Result<UUID, Error> = .success(expected)
    let serverResponse = try? MKServerResponse(fromResult: result)
    guard case let .success(actual) = serverResponse else {
      XCTFail()
      return
    }
    XCTAssertEqual(expected, actual)
  }

  public func testInitFromResultURL() {
    let expected = URL.random()
    let result: Result<UUID, Error> =
      .failure(MKError.authenticationRequired(MockAuthenticationRedirect(url: expected)))
    let serverResponse = try? MKServerResponse(fromResult: result)
    guard case let .failure(actual) = serverResponse else {
      XCTFail()
      return
    }
    XCTAssertEqual(expected, actual)
  }

  public func testInitFromResultFailure() {
    let expected = UUID()
    let result: Result<UUID, Error> = .failure(MockError(value: expected))
    do {
      _ = try MKServerResponse(fromResult: result)
    } catch let mockError as MockError<UUID> {
      XCTAssertEqual(mockError.value, expected)
      return
    } catch {
      XCTFail(error.localizedDescription)
      return
    }
    XCTFail()
  }
}
