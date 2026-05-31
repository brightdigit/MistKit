//
//  WebIndexHTML.swift
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

#if canImport(Hummingbird)
  internal import Foundation

  /// Loader for the web command's interactive page served by `WebServer`.
  ///
  /// The HTML, CSS, and JS modules live under `Resources/` and are read
  /// from `Bundle.module` on first access, then cached in memory so each
  /// request serves the same `ByteBuffer`. The mode toggle in `index.html`
  /// lets users compare MistKit (server-side) and CloudKit JS (browser-
  /// side) against the same CloudKit container.
  internal enum WebIndexHTML {
    internal static let content: String = loadContent()
    /// Cached extracted CSS file body served at `GET /styles.css`.
    internal static let stylesheet: String = loadResource(
      name: "styles", extension: "css"
    )

    /// Cached JS module bodies, keyed by the path the browser requests
    /// (e.g. `"app.js"`). Populated once from the bundled `js/`
    /// subdirectory; missing files surface as a preconditionFailure on
    /// boot so a typo'd `<script src>` doesn't masquerade as a 404 in
    /// production.
    internal static let jsModules: [String: String] = loadJSModules()

    private static func loadContent() -> String {
      loadResource(name: "index", extension: "html")
    }

    private static func loadResource(name: String, extension ext: String) -> String {
      guard
        let url = Bundle.module.url(forResource: name, withExtension: ext),
        let content = try? String(contentsOf: url, encoding: .utf8)
      else {
        preconditionFailure(
          "Resources/\(name).\(ext) missing from MistDemoKit bundle"
        )
      }
      return content
    }

    private static func loadJSModules() -> [String: String] {
      let names = [
        "app", "mode", "pending", "auth",
        "records", "zones", "subscriptions",
        "tokens", "assets", "users",
      ]
      var modules: [String: String] = [:]
      modules.reserveCapacity(names.count)
      for name in names {
        guard
          let url = Bundle.module.url(
            forResource: name, withExtension: "js", subdirectory: "js"
          ),
          let body = try? String(contentsOf: url, encoding: .utf8)
        else {
          preconditionFailure(
            "Resources/js/\(name).js missing from MistDemoKit bundle"
          )
        }
        modules["\(name).js"] = body
      }
      return modules
    }
  }
#endif
