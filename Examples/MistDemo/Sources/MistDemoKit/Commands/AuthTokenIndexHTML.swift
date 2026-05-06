//
//  AuthTokenIndexHTML.swift
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
  // swiftlint:disable line_length indentation_width
  /// Inlined CloudKit auth-flow page served by `AuthTokenCommand`.
  ///
  /// Held here as a Swift raw string so MistDemoKit doesn't need a SwiftPM resource
  /// bundle — that bundle would fail iOS-family CodeSign in CI even though the
  /// auth-token CLI flow only runs on macOS / Linux.
  internal enum AuthTokenIndexHTML {
    internal static let content: String = #"""
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>MistKit CloudKit Authentication Example</title>
          <style>
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  min-height: 100vh;
                  margin: 0;
                  background-color: #f5f5f7;
              }
              .container {
                  background: white;
                  padding: 40px;
                  border-radius: 12px;
                  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
                  max-width: 500px;
              }
              h1 {
                  color: #1d1d1f;
                  font-size: 28px;
                  margin-bottom: 20px;
              }
              p {
                  color: #6e6e73;
                  font-size: 16px;
                  line-height: 1.5;
                  margin-bottom: 30px;
              }

              .status {
                  margin-top: 20px;
                  padding: 12px;
                  border-radius: 8px;
                  font-size: 14px;
              }
              .status.success {
                  background-color: #d1f5d3;
                  color: #1d5e20;
              }
              .status.error {
                  background-color: #fdd;
                  color: #c00;
              }
              .user-info {
                  margin-top: 20px;
                  text-align: left;
                  background-color: #f5f5f7;
                  padding: 16px;
                  border-radius: 8px;
              }
              .user-info h3 {
                  margin-top: 0;
                  color: #1d1d1f;
                  font-size: 18px;
              }
              .user-info pre {
                  background-color: #fff;
                  padding: 12px;
                  border-radius: 6px;
                  overflow-x: auto;
                  font-size: 13px;
                  margin: 8px 0;
              }
              .loading {
                  display: none;
                  color: #86868b;
                  margin-top: 20px;
              }
              .token-display {
                  margin-top: 20px;
                  padding: 16px;
                  background-color: #f0f9ff;
                  border: 1px solid #0369a1;
                  border-radius: 8px;
              }
              .token-display h3 {
                  margin-top: 0;
                  color: #0369a1;
                  font-size: 18px;
              }
              .token-value {
                  font-family: 'Courier New', monospace;
                  font-size: 12px;
                  word-break: break-all;
                  background-color: #fff;
                  padding: 8px;
                  border-radius: 4px;
                  margin: 8px 0;
                  user-select: all;
              }
              .copy-button {
                  background-color: #0369a1;
                  color: white;
                  border: none;
                  padding: 8px 16px;
                  border-radius: 6px;
                  cursor: pointer;
                  font-size: 14px;
              }
              .copy-button:hover {
                  background-color: #0c4a6e;
              }
              .signout-button {
                  background-color: #ff3b30;
                  color: white;
                  border: none;
                  padding: 8px 16px;
                  border-radius: 6px;
                  cursor: pointer;
                  font-size: 14px;
                  margin-top: 10px;
              }
              .signout-button:hover {
                  background-color: #d70015;
              }
          </style>
          <script src="https://cdn.apple-cloudkit.com/ck/2/cloudkit.js" onerror="console.log('Failed to load CloudKit.js')"></script>
      </head>
      <body>
          <div class="container">
              <h1>MistKit CloudKit Example</h1>
              <p>Sign in with your Apple ID to test CloudKit Web Services authentication and API access.</p>

              <div id="signin-button"></div>
              <button id="signout-button" class="signout-button" style="display: none;">Sign Out</button>

              <div id="loading" class="loading">Authenticating...</div>
              <div id="status"></div>

              <!--
                  Manual fallback: shown when polling container._auth._ckSession times out.
                  This form lets the user copy the token from devtools and paste it in.
              -->
              <div id="manual-token-form" style="display: none; margin-top: 16px; padding: 12px; border: 1px solid #d0d7de; border-radius: 6px; background: #f6f8fa;">
                  <h3 style="margin-top: 0;">Paste Web Auth Token Manually</h3>
                  <p style="font-size: 13px; color: #57606a;">
                      Automatic capture failed (CloudKit's auth iframe is sandboxed).
                      Open DevTools &rarr; Application &rarr; Cookies &rarr; <code>icloud.com</code>,
                      find a cookie value starting with <code>158__</code>, and paste it below.
                  </p>
                  <input id="manual-token-input" type="text" placeholder="158__..." style="width: 100%; padding: 8px; box-sizing: border-box; font-family: monospace;">
                  <button id="manual-token-submit" type="button" style="margin-top: 8px; padding: 8px 16px;">Submit Token</button>
              </div>

              <div id="user-info"></div>
          </div>

          <script>
      \#(Self.scriptAuth)
      \#(Self.scriptDisplay)
      \#(Self.scriptInit)
          </script>
      </body>
      </html>
      """#
  }
// swiftlint:enable line_length indentation_width
#endif
