import CelestraKit
import Foundation
import MistKit
import Testing

@testable import CelestraCloudKit

@Suite("BatchOperationResult Tests")
internal struct BatchOperationResultTests {
  @Test("Success rate with all successes")
  internal func testSuccessRateAllSuccess() {
    var result = BatchOperationResult()

    // Add 5 successful records
    let successRecords = createTestRecords(count: 5)
    result.appendSuccesses(successRecords)

    #expect(result.successCount == 5)
    #expect(result.failureCount == 0)
    #expect(result.totalProcessed == 5)
    #expect(result.successRate == 100.0)
    #expect(result.isFullSuccess == true)
    #expect(result.isFullFailure == false)
  }

  @Test("Success rate with all failures")
  internal func testSuccessRateAllFailure() {
    var result = BatchOperationResult()

    // Add 3 failed records
    let failedArticles = createTestArticles(count: 3)
    let testError = NSError(domain: "Test", code: 1, userInfo: nil)

    for article in failedArticles {
      result.appendFailure(article: article, error: testError)
    }

    #expect(result.successCount == 0)
    #expect(result.failureCount == 3)
    #expect(result.totalProcessed == 3)
    #expect(result.successRate == 0.0)
    #expect(result.isFullSuccess == false)
    #expect(result.isFullFailure == true)
  }

  @Test("Success rate with mixed results")
  internal func testSuccessRateMixed() {
    var result = BatchOperationResult()

    // Add 6 successes
    result.appendSuccesses(createTestRecords(count: 6))

    // Add 4 failures
    let testError = NSError(domain: "Test", code: 1, userInfo: nil)
    for article in createTestArticles(count: 4) {
      result.appendFailure(article: article, error: testError)
    }

    #expect(result.successCount == 6)
    #expect(result.failureCount == 4)
    #expect(result.totalProcessed == 10)
    #expect(result.successRate == 60.0)
    #expect(result.isFullSuccess == false)
    #expect(result.isFullFailure == false)
  }

  @Test("Success rate with empty result")
  internal func testSuccessRateEmpty() {
    let result = BatchOperationResult()

    #expect(result.successCount == 0)
    #expect(result.failureCount == 0)
    #expect(result.totalProcessed == 0)
    #expect(result.successRate == 0.0)
    #expect(result.isFullSuccess == false)
    #expect(result.isFullFailure == false)
  }

  @Test("Append combines two results")
  internal func testAppendCombinesResults() {
    var result1 = BatchOperationResult()
    result1.appendSuccesses(createTestRecords(count: 3))

    let testError = NSError(domain: "Test", code: 1, userInfo: nil)
    result1.appendFailure(article: createTestArticles(count: 1)[0], error: testError)

    var result2 = BatchOperationResult()
    result2.appendSuccesses(createTestRecords(count: 2))
    result2.appendFailure(article: createTestArticles(count: 1)[0], error: testError)

    // Append result2 to result1
    result1.append(result2)

    #expect(result1.successCount == 5)  // 3 + 2
    #expect(result1.failureCount == 2)  // 1 + 1
    #expect(result1.totalProcessed == 7)
    #expect(result1.successRate == (5.0 / 7.0) * 100.0)
  }

  @Test("IsFullSuccess only true when all succeed")
  internal func testIsFullSuccess() {
    var result = BatchOperationResult()

    // Empty result - not full success
    #expect(result.isFullSuccess == false)

    // Add successes only
    result.appendSuccesses(createTestRecords(count: 3))
    #expect(result.isFullSuccess == true)

    // Add a failure - no longer full success
    let testError = NSError(domain: "Test", code: 1, userInfo: nil)
    result.appendFailure(article: createTestArticles(count: 1)[0], error: testError)
    #expect(result.isFullSuccess == false)
  }

  @Test("IsFullFailure only true when all fail")
  internal func testIsFullFailure() {
    var result = BatchOperationResult()
    let testError = NSError(domain: "Test", code: 1, userInfo: nil)

    // Empty result - not full failure
    #expect(result.isFullFailure == false)

    // Add failures only
    for article in createTestArticles(count: 3) {
      result.appendFailure(article: article, error: testError)
    }
    #expect(result.isFullFailure == true)

    // Add a success - no longer full failure
    result.appendSuccesses(createTestRecords(count: 1))
    #expect(result.isFullFailure == false)
  }

  @Test("AppendSuccesses adds multiple records")
  internal func testAppendSuccesses() {
    var result = BatchOperationResult()

    let records = createTestRecords(count: 5)
    result.appendSuccesses(records)

    #expect(result.successCount == 5)
    #expect(result.successfulRecords.count == 5)
  }

  @Test("AppendFailure adds single failure")
  internal func testAppendFailure() {
    var result = BatchOperationResult()

    let article = createTestArticles(count: 1)[0]
    let testError = NSError(domain: "TestDomain", code: 42, userInfo: nil)

    result.appendFailure(article: article, error: testError)

    #expect(result.failureCount == 1)
    #expect(result.failedRecords.count == 1)
    #expect(result.failedRecords[0].article.guid == article.guid)
  }

  // MARK: - Helper Methods

  /// Create test RecordInfo objects
  private func createTestRecords(count: Int) -> [RecordInfo] {
    (0..<count).map { index in
      RecordInfo(
        recordName: "record-\(index)",
        recordType: "Article",
        recordChangeTag: "tag-\(index)",
        fields: [
          "guid": .string("guid-\(index)"),
          "title": .string("Article \(index)"),
        ]
      )
    }
  }

  /// Create test Article objects
  private func createTestArticles(count: Int) -> [Article] {
    (0..<count).map { index in
      Article(
        recordName: "article-\(index)",
        recordChangeTag: nil,
        feedRecordName: "feed-test",
        guid: "guid-\(index)",
        title: "Test Article \(index)",
        url: "https://example.com/article-\(index)",
        fetchedAt: Date(),
        ttlDays: 30
      )
    }
  }
}
