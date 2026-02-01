//
//  BrowserOpenerTests.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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
@testable import MistDemo

@Suite("BrowserOpener Tests")
struct BrowserOpenerTests {

  @Test("openBrowser handles valid HTTPS URL without crashing")
  func openBrowserValidHTTPSURL() {
    // This test verifies the function doesn't crash with a valid URL
    // We can't easily verify the browser opens in a test environment
    BrowserOpener.openBrowser(url: "https://www.apple.com")
    // No crash = success
  }

  @Test("openBrowser handles valid HTTP URL without crashing")
  func openBrowserValidHTTPURL() {
    BrowserOpener.openBrowser(url: "http://www.example.com")
    // No crash = success
  }

  @Test("openBrowser handles invalid URL without crashing")
  func openBrowserInvalidURL() {
    // Invalid URLs should be handled gracefully
    BrowserOpener.openBrowser(url: "not a valid url")
    // No crash = success
  }

  @Test("openBrowser handles empty string without crashing")
  func openBrowserEmptyString() {
    BrowserOpener.openBrowser(url: "")
    // No crash = success
  }

  @Test("openBrowser handles malformed URL without crashing")
  func openBrowserMalformedURL() {
    let malformedURLs = [
      "ht!tp://example.com",
      "://example.com",
      "http://",
      "ftp://",
      "javascript:alert(1)"
    ]

    for url in malformedURLs {
      BrowserOpener.openBrowser(url: url)
      // No crash = success
    }
  }

  @Test("openBrowser handles URL with special characters without crashing")
  func openBrowserSpecialCharacters() {
    let urls = [
      "https://example.com/path?query=value&other=123",
      "https://example.com/path#fragment",
      "https://example.com/path%20with%20spaces",
      "https://user:pass@example.com/path"
    ]

    for url in urls {
      BrowserOpener.openBrowser(url: url)
      // No crash = success
    }
  }

  @Test("openBrowser handles CloudKit-specific URLs without crashing")
  func openBrowserCloudKitURLs() {
    // Test with typical CloudKit console URLs
    let cloudKitURLs = [
      "https://icloud.developer.apple.com/dashboard/",
      "https://icloud.developer.apple.com/dashboard/auth",
      "https://developer.apple.com/account/"
    ]

    for url in cloudKitURLs {
      BrowserOpener.openBrowser(url: url)
      // No crash = success
    }
  }

  @Test("openBrowser handles very long URL without crashing")
  func openBrowserVeryLongURL() {
    let longURL = "https://example.com/" + String(repeating: "a", count: 10000)
    BrowserOpener.openBrowser(url: longURL)
    // No crash = success
  }

  @Test("openBrowser handles localhost URLs without crashing")
  func openBrowserLocalhost() {
    let localhostURLs = [
      "http://localhost:8080",
      "http://127.0.0.1:3000",
      "http://[::1]:8080"
    ]

    for url in localhostURLs {
      BrowserOpener.openBrowser(url: url)
      // No crash = success
    }
  }

  @Test("openBrowser handles custom URL schemes without crashing")
  func openBrowserCustomSchemes() {
    // Custom schemes might not open, but shouldn't crash
    let customSchemes = [
      "mailto:test@example.com",
      "tel:+1234567890",
      "cloudkit://",
      "custom-app://action"
    ]

    for url in customSchemes {
      BrowserOpener.openBrowser(url: url)
      // No crash = success
    }
  }
}
