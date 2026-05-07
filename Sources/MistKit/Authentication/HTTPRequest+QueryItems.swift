//
//  HTTPRequest+QueryItems.swift
//  MistKit
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

internal import Foundation
internal import HTTPTypes

extension HTTPRequest {
  /// Appends the given query items to this request's path, preserving any
  /// existing query string.
  internal mutating func appendQueryItems(_ items: [URLQueryItem]) {
    let pathString = path ?? ""
    let parts = pathString.split(separator: "?", maxSplits: 1)
    let cleanPath = String(parts.first ?? "")

    var components = URLComponents()
    components.path = cleanPath
    if parts.count > 1, let existing = URLComponents(string: "?" + String(parts[1])) {
      components.queryItems = existing.queryItems ?? []
    }

    var queryItems = components.queryItems ?? []
    queryItems.append(contentsOf: items)
    components.queryItems = queryItems

    if let query = components.query {
      path = components.path + "?" + query
    } else {
      path = components.path
    }
  }
}
