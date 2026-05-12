//
//  BrowserFlagResolver.swift
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

/// Resolves the "should we open the browser on startup?" decision from
/// the two mutually-exclusive CLI flags into a single boolean.
///
/// - `--no-browser` sets `no.browser=true` → resolves to `false` (wins).
/// - `--browser` sets `browser=true` → resolves to `true`.
/// - Neither set → falls back to the per-command default.
internal enum BrowserFlagResolver {
  internal static func resolve(
    configReader: MistDemoConfiguration,
    default defaultValue: Bool
  ) -> Bool {
    let noBrowser = configReader.bool(forKey: "no.browser", default: false)
    if noBrowser {
      return false
    }
    let browser = configReader.bool(forKey: "browser", default: false)
    if browser {
      return true
    }
    return defaultValue
  }
}
