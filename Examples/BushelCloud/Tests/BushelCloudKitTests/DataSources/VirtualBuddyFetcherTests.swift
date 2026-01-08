//
//  VirtualBuddyFetcherTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// All VirtualBuddy tests wrapped in a serialized suite to prevent mock handler conflicts
@Suite(
  "VirtualBuddyFetcher Tests",
  .serialized,
  .enabled(
    if: {
      #if os(macOS) || os(Linux)
        return true
      #else
        return false
      #endif
    }()
  )
)
internal struct VirtualBuddyFetcherTests {
  // MARK: - Initialization Tests

  @Suite("Initialization")
  internal struct InitializationTests {
    @Test("Initialize with environment variable")
    internal func testInitWithEnvironmentVariable() throws {
      // Set environment variable
      setenv("VIRTUALBUDDY_API_KEY", "test-api-key-123", 1)
      defer { unsetenv("VIRTUALBUDDY_API_KEY") }

      // Initialize fetcher
      let fetcher = VirtualBuddyFetcher()

      // Should succeed when environment variable is set
      #expect(fetcher != nil)
    }

    @Test("Initialize fails without environment variable")
    internal func testInitFailsWithoutEnvironmentVariable() throws {
      // Ensure environment variable is not set
      unsetenv("VIRTUALBUDDY_API_KEY")

      // Initialize fetcher
      let fetcher = VirtualBuddyFetcher()

      // Should fail when environment variable is not set
      #expect(fetcher == nil)
    }

    @Test("Initialize fails with empty environment variable")
    internal func testInitFailsWithEmptyEnvironmentVariable() throws {
      // Set empty environment variable
      setenv("VIRTUALBUDDY_API_KEY", "", 1)
      defer { unsetenv("VIRTUALBUDDY_API_KEY") }

      // Initialize fetcher
      let fetcher = VirtualBuddyFetcher()

      // Should fail when environment variable is empty
      #expect(fetcher == nil)
    }

    @Test("Initialize with explicit API key")
    internal func testExplicitInit() throws {
      // Initialize with explicit API key
      let fetcher = VirtualBuddyFetcher(apiKey: "explicit-api-key")

      // Initialization always succeeds (non-failable init)
      // Actual functionality validated by fetch operation tests
      _ = fetcher
    }

    @Test("Initialize with custom dependencies")
    internal func testCustomDependencies() throws {
      let customDecoder = JSONDecoder()
      customDecoder.dateDecodingStrategy = .iso8601

      let config = URLSessionConfiguration.default
      config.protocolClasses = [MockURLProtocol.self]
      let customSession = URLSession(configuration: config)

      // Initialize with custom decoder and session
      let fetcher = VirtualBuddyFetcher(
        apiKey: "test-key",
        decoder: customDecoder,
        urlSession: customSession
      )

      // Initialization always succeeds (non-failable init)
      // Custom dependencies validated by fetch operation tests
      _ = fetcher
    }
  }

  // MARK: - Empty Fetch Tests

  @Suite("Empty Fetch")
  internal struct EmptyFetchTests {
    @Test("fetch() returns empty array")
    internal func testFetchReturnsEmptyArray() async throws {
      let fetcher = VirtualBuddyFetcher(apiKey: "test-key")

      let result = try await fetcher.fetch()

      #expect(result.isEmpty)
    }
  }

  // MARK: - Enrichment Success Tests

  @Suite("Enrichment Success")
  internal struct EnrichmentSuccessTests {
    @Test("Enrich single signed image")
    internal func testEnrichSingleSignedImage() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Configure mock response
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddySonoma1421Response.data(using: .utf8)!
        return (response, data)
      }

      // Create fetcher with mock session
      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      // Test with Sonoma 14.2.1 image
      let images = [TestFixtures.sonoma1421]
      let enriched = try await fetcher.fetch(existingImages: images)

      // Verify enrichment
      #expect(enriched.count == 1)
      let enrichedImage = try #require(enriched.first)

      #expect(enrichedImage.buildNumber == "23C71")
      #expect(enrichedImage.isSigned == true)
      #expect(enrichedImage.source == "tss.virtualbuddy.app")
      #expect(enrichedImage.notes == "SUCCESS")
      #expect(enrichedImage.sourceUpdatedAt != nil)
    }

    @Test("Enrich single unsigned image")
    internal func testEnrichSingleUnsignedImage() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Configure mock response for unsigned build
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddyUnsignedResponse.data(using: .utf8)!
        return (response, data)
      }

      // Create fetcher with mock session
      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      // Create test image with matching build number
      let testImage = RestoreImageRecord(
        version: "15.1",
        buildNumber: "24B5024e",
        releaseDate: Date(),
        downloadURL: URL(string: "https://example.com/test.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: true,
        source: "test",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let enriched = try await fetcher.fetch(existingImages: [testImage])

      // Verify unsigned status
      #expect(enriched.count == 1)
      let enrichedImage = try #require(enriched.first)

      #expect(enrichedImage.buildNumber == "24B5024e")
      #expect(enrichedImage.isSigned == false)
      #expect(enrichedImage.source == "tss.virtualbuddy.app")
      #expect(enrichedImage.notes == "This device isn't eligible for the requested build.")
    }

    @Test("Skip file URL images")
    internal func testSkipsFileURLImages() async throws {
      let fetcher = VirtualBuddyFetcher(apiKey: "test-key")

      // Create image with file:// URL
      let fileImage = RestoreImageRecord(
        version: "14.0",
        buildNumber: "23A344",
        releaseDate: Date(),
        downloadURL: URL(string: "file:///path/to/local.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: false,
        source: "local",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let result = try await fetcher.fetch(existingImages: [fileImage])

      // File URLs should pass through unchanged (no API call)
      #expect(result.count == 1)
      let resultImage = try #require(result.first)
      #expect(resultImage.source == "local")  // Unchanged
      #expect(resultImage.downloadURL.scheme == "file")
    }

    @Test("Return empty for empty input")
    internal func testEmptyImageList() async throws {
      let fetcher = VirtualBuddyFetcher(apiKey: "test-key")

      let result = try await fetcher.fetch(existingImages: [])

      #expect(result.isEmpty)
    }

    @Test("Mixed HTTP and file URLs")
    internal func testMixedHTTPAndFileURLs() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Configure mock response
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddySonoma1421Response.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      // Mix of file and HTTP URLs
      let fileImage = RestoreImageRecord(
        version: "14.0",
        buildNumber: "23A344",
        releaseDate: Date(),
        downloadURL: URL(string: "file:///local.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: false,
        source: "local",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let images = [fileImage, TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      #expect(result.count == 2)
      // File URL unchanged, HTTP enriched
      #expect(result[0].source == "local")
      #expect(result[1].source == "tss.virtualbuddy.app")
    }
  }

  // MARK: - Error Handling Tests

  @Suite("Error Handling")
  internal struct ErrorHandlingTests {
    @Test("Build number mismatch preserves original")
    internal func testBuildNumberMismatch() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Response has wrong build number
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddyBuildMismatchResponse.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let images = [TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      // Should preserve original when build number doesn't match
      #expect(result.count == 1)
      let resultImage = try #require(result.first)
      #expect(resultImage.source == "ipsw.me")  // Original source preserved
      #expect(resultImage.buildNumber == "23C71")
    }

    @Test("HTTP 400 error preserves original")
    internal func testHTTP400Error() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Return HTTP 400
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 400,
          httpVersion: nil,
          headerFields: nil
        )!
        return (response, nil)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let images = [TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      // Should preserve original on error
      #expect(result.count == 1)
      let resultImage = try #require(result.first)
      #expect(resultImage.source == "ipsw.me")  // Original preserved
    }

    @Test("HTTP 429 rate limit error preserves original")
    internal func testHTTP429RateLimitError() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Return HTTP 429
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 429,
          httpVersion: nil,
          headerFields: nil
        )!
        return (response, nil)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let images = [TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      // Should preserve original on rate limit
      #expect(result.count == 1)
      #expect(result.first?.source == "ipsw.me")
    }

    @Test("HTTP 500 server error preserves original")
    internal func testHTTP500Error() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Return HTTP 500
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 500,
          httpVersion: nil,
          headerFields: nil
        )!
        return (response, nil)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let images = [TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      // Should preserve original on server error
      #expect(result.count == 1)
      #expect(result.first?.source == "ipsw.me")
    }

    @Test("Network error preserves original")
    internal func testNetworkError() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Simulate network error
      MockURLProtocol.requestHandler = { _ in
        throw NSError(
          domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil
        )
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let images = [TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      // Should preserve original on network error
      #expect(result.count == 1)
      #expect(result.first?.source == "ipsw.me")
    }

    @Test("Invalid JSON response preserves original")
    internal func testInvalidJSONResponse() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      // Return invalid JSON
      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        return (response, invalidJSON)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let images = [TestFixtures.sonoma1421]
      let result = try await fetcher.fetch(existingImages: images)

      // Should preserve original on decode error
      #expect(result.count == 1)
      #expect(result.first?.source == "ipsw.me")
    }
  }

  // MARK: - Rate Limiting Tests

  @Suite("Rate Limiting")
  internal struct RateLimitingTests {
    @Test("No delay for single image")
    internal func testNoDelayForSingleImage() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddySonoma1421Response.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let startTime = Date()
      let images = [TestFixtures.sonoma1421]
      _ = try await fetcher.fetch(existingImages: images)
      let duration = Date().timeIntervalSince(startTime)

      // Should complete quickly (no 2.5-3.5 second delay)
      #expect(duration < 1.0)  // Allow some network overhead but no delay
    }

    @Test("Delay between multiple images")
    internal func testDelayBetweenRequests() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddySonoma1421Response.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      // Two HTTP images
      let image1 = TestFixtures.sonoma1421
      let image2 = RestoreImageRecord(
        version: "14.3",
        buildNumber: "23D56",
        releaseDate: Date(),
        downloadURL: URL(string: "https://example.com/second.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: false,
        source: "test",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let startTime = Date()
      _ = try await fetcher.fetch(existingImages: [image1, image2])
      let duration = Date().timeIntervalSince(startTime)

      // Should have delay between requests (2.5-3.5 seconds)
      #expect(duration >= 2.0)  // At least close to the minimum delay
      #expect(duration < 5.0)  // But not too long
    }

    @Test("No delay for file URLs")
    internal func testNoDelayForFileURLs() async throws {
      let fetcher = VirtualBuddyFetcher(apiKey: "test-key")

      let fileImage1 = RestoreImageRecord(
        version: "14.0",
        buildNumber: "23A344",
        releaseDate: Date(),
        downloadURL: URL(string: "file:///path1.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: false,
        source: "local",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let fileImage2 = RestoreImageRecord(
        version: "14.1",
        buildNumber: "23B5056e",
        releaseDate: Date(),
        downloadURL: URL(string: "file:///path2.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: false,
        source: "local",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let startTime = Date()
      _ = try await fetcher.fetch(existingImages: [fileImage1, fileImage2])
      let duration = Date().timeIntervalSince(startTime)

      // Should complete immediately (file URLs skipped, no API calls)
      #expect(duration < 0.5)
    }
  }

  // MARK: - API Response Parsing Tests

  @Suite("API Response Parsing")
  internal struct APIResponseParsingTests {
    @Test("Parse signed response correctly")
    internal func testParseSignedResponse() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddySignedResponse.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let testImage = RestoreImageRecord(
        version: "15.0",
        buildNumber: "24A5327a",
        releaseDate: Date(),
        downloadURL: URL(string: "https://example.com/test.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: true,
        source: "test",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let result = try await fetcher.fetch(existingImages: [testImage])

      #expect(result.count == 1)
      let enriched = try #require(result.first)
      #expect(enriched.isSigned == true)
      #expect(enriched.notes == "SUCCESS")
    }

    @Test("Parse unsigned response correctly")
    internal func testParseUnsignedResponse() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      MockURLProtocol.requestHandler = { _ in
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddyUnsignedResponse.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "test-key", urlSession: mockSession)

      let testImage = RestoreImageRecord(
        version: "15.1",
        buildNumber: "24B5024e",
        releaseDate: Date(),
        downloadURL: URL(string: "https://example.com/test.ipsw")!,
        fileSize: 1_000,
        sha256Hash: "",
        sha1Hash: "",
        isSigned: nil,
        isPrerelease: true,
        source: "test",
        notes: nil,
        sourceUpdatedAt: nil
      )

      let result = try await fetcher.fetch(existingImages: [testImage])

      #expect(result.count == 1)
      let enriched = try #require(result.first)
      #expect(enriched.isSigned == false)
      #expect(enriched.notes?.contains("isn't eligible") == true)
    }

    @Test("URL construction includes API key and IPSW parameter")
    internal func testURLConstruction() async throws {
      // Configure mock URLSession
      let config = URLSessionConfiguration.ephemeral
      config.protocolClasses = [MockURLProtocol.self]
      let mockSession = URLSession(configuration: config)

      var capturedRequest: URLRequest?
      MockURLProtocol.requestHandler = { request in
        capturedRequest = request
        let url = URL(string: "https://tss.virtualbuddy.app")!
        let response = HTTPURLResponse(
          url: url,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = TestFixtures.virtualBuddySonoma1421Response.data(using: .utf8)!
        return (response, data)
      }

      let fetcher = VirtualBuddyFetcher(apiKey: "my-api-key-123", urlSession: mockSession)

      _ = try await fetcher.fetch(existingImages: [TestFixtures.sonoma1421])

      // Verify URL was constructed correctly
      let request = try #require(capturedRequest)
      let url = try #require(request.url)

      #expect(url.host == "tss.virtualbuddy.app")
      #expect(url.path == "/v1/status")

      let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      let queryItems = try #require(components?.queryItems)

      #expect(queryItems.contains(where: { $0.name == "apiKey" && $0.value == "my-api-key-123" }))
      #expect(queryItems.contains(where: { $0.name == "ipsw" }))
    }
  }
}  // VirtualBuddyFetcherAllTests
