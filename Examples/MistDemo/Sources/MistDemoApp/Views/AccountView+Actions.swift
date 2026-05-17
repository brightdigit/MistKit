//
//  AccountView+Actions.swift
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

#if canImport(SwiftUI) && canImport(CloudKit)
  import CloudKit
  import SwiftUI

  #if canImport(AppKit)
    import AppKit
  #elseif canImport(UIKit)
    import UIKit
  #endif

  extension AccountView {
    internal func seedTokenIfNeeded() {
      guard apiToken.isEmpty else {
        return
      }
      if let envValue = ProcessInfo.processInfo.environment[Self.envVarName],
        !envValue.isEmpty,
        !envValue.hasPrefix("${")
      {
        apiToken = envValue
        tokenSource = .environment
      }
    }

    internal func fetchToken() async {
      fetchingWebAuthToken = true
      webAuthTokenError = nil
      webAuthToken = nil
      defer { fetchingWebAuthToken = false }
      do {
        let token = try await service.fetchWebAuthToken(
          apiToken: apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        webAuthToken = token
      } catch {
        webAuthTokenError = error.localizedDescription
      }
    }

    internal func copy(_ value: String) {
      #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
      #elseif canImport(UIKit) && !os(tvOS) && !os(watchOS)
        UIPasteboard.general.string = value
      #endif
    }
  }
#endif
